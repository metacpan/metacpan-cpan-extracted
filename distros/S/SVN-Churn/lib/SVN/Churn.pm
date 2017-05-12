package SVN::Churn;
use strict;
use warnings;
our $VERSION = '0.02';
use Chart::Strip;
use Date::Parse qw( str2time );
use List::Util qw( min max );
use SVN::Log;
use Storable qw( nstore retrieve );
use String::ShellQuote qw( shell_quote );
use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( path database revisions skip_to granularity ));

=head1 NAME

SVN::Churn - generate a graph for repository churn

=head1 SYNOPSIS

  use SVN::Churn;
  my $churn = SVN::Churn->new(
      path     => 'http://opensource.fotango.com/svn/trunk/SVN-Churn',
      database => 'churn.db' );
  $churn->update;
  $churn->save;
  $churn->graph( 'churn.png' );

=head1 DESCRIPTION

SVN::Churn is a module for generating Churn graphs.  Churn graphs
simply track the number of changed lines in a repository, grouped by a
time period; they might be useful for judging the stability of a
codebase, or the activeness of a project, or they may not be.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new({
        granularity => 60 * 60 * 24,
        revisions   => [],
        @_,
    });
    return $self;
}

sub save {
    my $self = shift;
    nstore $self, $self->database;
}

sub load {
    my $class = shift;
    my $from = shift;
    return retrieve $from;
}

sub head_revision {
    my $self = shift;
    if (eval {
        # load SVN::Core before SVN::Ra for future compatibility -- clkao
        require SVN::Core;
        require SVN::Ra;
        1;
    }) { # we have the bindings
        return SVN::Ra->new(url => $self->path)->get_latest_revnum;
    }
    else {
        my $path = shell_quote $self->path;
        return $1
          if `svn log -r HEAD $path` =~ m{^r(\d+) }m;
        my ($parent, $chunk) = $self->path =~ m{(.*?/)([^/]+/?)$}
          or die "couldn't guess what the parent was for ".$self->path;
        $parent = shell_quote $parent;
        `svn ls -v $parent` =~ m{^\s*(\d+).*? \Q$chunk\E$}m
          or die "couldn't figure out head revision";
        return $1;
    }
}


sub start_at {
    my $self = shift;
    if (my $skip_to = $self->skip_to) {
        $self->skip_to( 0 ); # clear the flag
        return $skip_to;
    }
    my $highest = max map { $_->{revision} } @{ $self->revisions };
    return $highest ? $highest + 1 : 1;
}

sub update {
    my $self = shift;
    my ($from, $to) = ( $self->start_at, $self->head_revision );
    return if $from > $to;
    my $revisions = SVN::Log::retrieve( $self->path, $from, $to );
    local $| = 1;
    for my $revision (@$revisions) {
        print "r$revision->{revision} | $revision->{author} | $revision->{date}";
        $self->add_churn_to( $revision );
        print " -$revision->{lines_removed}+$revision->{lines_added}\n";
        push @{ $self->revisions }, $revision;
    }
}

sub get_diff {
    my $self = shift;
    my $revision = shift;
    my $to = $revision->{revision};
    my $from = $to - 1;
    my $path = shell_quote $self->path;

    my @diff = `svn diff -r $from:$to $path 2>/dev/null`;
    # if it's nonzero, it could be that it's the initial add, so fake
    # it so it's a total add diff
    if ($?) {
        # apart from cat doesn't work on paths,  hmmm
        # @diff = map "+$_", `svn cat -r $to $path` if $?;
    }

    return @diff;
}

sub add_churn_to {
    my $self = shift;
    my $revision = shift;

    my @diff = $self->get_diff( $revision );

    #print Dump $revision, \@diff;
    $revision->{ndate} = str2time $revision->{date};
    $revision->{lines_added} = $revision->{lines_removed} = 0;
    for (@diff) {
        next if /^[-+]{3,3} \S/;
        ++$revision->{lines_added}   if /^\+/;
        ++$revision->{lines_removed} if /^\-/;
    }
}

sub graph {
    my $self = shift;
    my $filename = shift;
    my $chart = Chart::Strip->new( title => 'Churn for '. $self->path );

    my @colours = qw( green red blue FF9900 990099 00FFFF 993300 CC0066 black );
    my $colour = 0;
    for my $key (qw( lines_added lines_removed )) {
        $chart->add_data(
            $self->churn_data( $key ),
            {
                style => 'line',
                color => $colours[ $colour++ % @colours ],
                label => $key,
            } );
    }
    open my $fh, ">$filename";
    local $^W; # XXX lazy
    print $fh $chart->png;
}

sub granulate {
    my $self = shift;
    my $time = shift;
    return int( $time / $self->granularity ) * $self->granularity;
}

sub churn_data {
    my $self = shift;
    my $key  = shift;

    my $from = $self->granulate( min map $_->{ndate}, @{ $self->revisions } );
    my $to   = $self->granulate( max map $_->{ndate}, @{ $self->revisions } );

    my %granular;
    # prefill with zeros
    while ($from <= $to) {
        $granular{ $from } = 0;
        $from += $self->granularity;
    }

    for my $revision (@{$self->revisions}) {
        $granular{ $self->granulate( $revision->{ndate} ) }
          += $revision->{ $key };
    }

    [ map {
        { time => $_, value => $granular{$_} }
    } sort { $a <=> $b } keys %granular ];
}

1;

__END__

=head1 TODO

=over

=item

Generate Graaph between dates

=item

Document a little more

=back

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright 2004 Fotango.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO


=cut
