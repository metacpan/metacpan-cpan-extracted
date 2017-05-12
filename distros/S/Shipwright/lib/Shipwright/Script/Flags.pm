package Shipwright::Script::Flags;

use strict;
use warnings;
use Shipwright::Util;

use base qw/App::CLI::Command Shipwright::Base Shipwright::Script/;
__PACKAGE__->mk_accessors(qw/add delete set mandatory/);

use Shipwright;
use List::MoreUtils qw/uniq/;

sub options {
    (
        'a|add=s'    => 'add',
        'd|delete=s' => 'delete',
        's|set=s'    => 'set',
        'mandatory'  => 'mandatory',
    );
}

sub run {
    my $self = shift;
    my $name = shift;

    confess_or_die "need name arg\n" unless $name;

    if ( $name =~ /^__/ ) {
        $self->log->fatal( "$name can't start as __" );
        return;
    }

    my $shipwright = Shipwright->new( repository => $self->repository, );

    my $flags = $shipwright->backend->flags;

    unless ( defined $self->add || defined $self->delete || defined $self->set )
    {

        # show without change
        $self->_show_flags( $flags, $name );
        return;
    }

    unless ( 1 == grep { defined $_ } $self->add, $self->delete, $self->set ) {
        confess_or_die "you should specify one and only one of add, delete and set\n";
    }

    my $list;

    if ( defined $self->add ) {
        $self->add( [ grep { /^[-\w]+$/ } split /,\s*/, $self->add ] );
        $list = [ uniq @{ $self->add }, @{ $flags->{$name} || [] } ];
    }
    elsif ( defined $self->delete ) {
        $self->delete( [ split /,\s*/, $self->delete ] );
        my %seen;    # lookup table
        @seen{ @{ $self->delete } } = ();

        $list = [ grep { !exists $seen{$_} } @{ $flags->{$name} || [] } ];

    }
    elsif ( defined $self->set ) {
        $list = [ grep { /^[-\w]+$/ } split /,\s*/, $self->set ];
    }

    if ( $self->mandatory ) {
        $flags->{__mandatory}{$name} = $list;
    }
    else {
        $flags->{$name} = $list;
    }

    $shipwright->backend->flags($flags);
    $self->_show_flags( $flags, $name );
}

sub _show_flags {
    my $self  = shift;
    my $flags = shift;
    my $name  = shift;

    my $changed;
    $changed = 1 if $self->add || $self->delete || $self->set;

    my $flags_info;
    if ( $self->mandatory ) {
        $self->log->fatal( 'successfully set mandatory flags' ) if $changed;
        if ( @{ $flags->{__mandatory}{$name} || [] } ) {
            $flags_info = join ', ', @{ $flags->{__mandatory}{$name} };
        }
        else {
            $flags_info = '*nothing*';
        }
        $self->log->fatal( "mandatory flags of $name are $flags_info" );
    }
    else {
        $self->log->fatal( 'successfully set flags' ) if $changed;
        if ( @{ $flags->{$name} || [] } ) {
            $flags_info =  join ', ', @{ $flags->{$name} };
        }
        else {
            $flags_info = '*nothing*';
        }
        $self->log->fatal( "flags of $name are $flags_info" );
    }

}

1;

__END__

=head1 NAME

Shipwright::Script::Flags - Maintain flags

=head1 SYNOPSIS

 shipwright flags mysql --add mysql
 shipwright flags cpan-DBD-mysql --add mysql

=head1 DESCRIPTION

The flags command is used for managing the flags feature of Shipwright. Flags
can be used to group sources in ways which allow a single shipyard to support
multiple variants of binary vessels. For example, if you are shipping some
software that requires a database, your repository can use flags to allow
binary vessels to be built for both MySQL and PostgreSQL from it.

For more information on using flags, see L<Shipwright::Manual::UsingFlags>.


=head1 OPTIONS

 --add, --delete, --set FLAGS   : specify the flags, split by commas
 --mandatory                    : set these flags as being required

=head1 GLOBAL OPTIONS

 -r [--repository] REPOSITORY   : specify the repository uri of our shipyard
 -l [--log-level] LOGLEVEL      : specify the log level
                                  (info, debug, warn, error, or fatal)
 --log-file FILENAME            : specify the log file


=head1 AUTHORS

sunnavy  C<< <sunnavy@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Shipwright is Copyright 2007-2015 Best Practical Solutions, LLC.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

