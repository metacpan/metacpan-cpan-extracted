package Statistics::Suggest;

#use 5.008008;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Statistics::Suggest ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.
    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Statistics::Suggest::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Statistics::Suggest', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

sub new {
    my $class = shift;
    my $self = bless {
        RType => 2,
        NNbr => 20,
        Alpha => 0.4,
        @_
    }, $class;

    return $self;
}

sub load_trans {
    my ($self, $trans) = @_;

    my $nusers = 0;
    my $nitems = 0;
    my $ntrans = 0;
    my @userid;
    my @itemid;

    for (@$trans) {
        my ($u, $i) = @$_;
        $ntrans ++;
        $nusers = $u if $u > $nusers;
        $nitems = $i if $i > $nitems;
        push @userid, $u;
        push @itemid, $i;
    }

    $self->{nusers} = $nusers;
    $self->{nitems} = $nitems;
    $self->{ntrans} = $ntrans;
    $self->{userid} = \@userid;
    $self->{itemid} = \@itemid;
}

sub init {
    my $self = shift;

    croak "necessary params not set" unless (
        defined($self->{nusers}) and defined($self->{nitems}) and defined($self->{ntrans})
            and defined($self->{userid}) and defined($self->{itemid})
                and defined($self->{RType}) and defined($self->{NNbr})
                    and ($self->{NNbr} != 2 or defined($self->{Alpha}))
                );

    $self->{RcmdHandle} = _SUGGEST_Init(
        map $self->{$_}, qw(nusers nitems ntrans userid itemid RType NNbr Alpha)
    );
}

sub estimate_alpha {
    my ($self, $nrcmd) = @_;

    croak "necessary params not set" unless (
        defined($self->{nusers}) and defined($self->{nitems}) and defined($self->{ntrans})
            and defined($self->{RType}) and defined($self->{NNbr})
        );

    $self->{NRcmd} = ($nrcmd || $self->{NRcmd});

    $self->{Alpha} = _SUGGEST_EstimateAlpha(
        map $self->{$_}, qw(nusers nitems ntrans userid itemid NNbr NRcmd)
    );
}

sub top_n {
    my ($self, $itemids, $nrcmd, $rcmds) = @_;

    croak "should init first" unless $self->{RcmdHandle};

    $self->{NRcmd} = ($nrcmd || $self->{NRcmd});

    return _SUGGEST_TopN(
        $self->{RcmdHandle}, scalar @$itemids, $itemids, $self->{NRcmd}, $$rcmds
    );
}

sub DESTROY {
    my $self = shift;

    if ($self->{RcmdHandle}) {
        _SUGGEST_Clean($self->{RcmdHandle});
    }
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Statistics::Suggest - Perl binding for collaborative filtering library SUGGEST.

=head1 INSTALLATION

Download SUGGEST from L<http://glaros.dtc.umn.edu/gkhome/suggest/download>.

Find C<libsuggest.a> which matches your environment and place it under
your library path (or specify its path with LIBS option as shown below).

Then do:

   perl Makefile.PL [LIBS='-L/where/to/find/libsuggest.a -lsuggest']
   make
   make test
   make install

Tested with suggest-1.0-linux.

=head1 SYNOPSIS

  use Statistics::Suggest;
  
  ## initialize SUGGEST with $data
  my $data = [
    # array of [$user_id, $item_id], ...
    [1, 1], [1, 2], [1, 4], [1, 5]
    [2, 1], [2, 2], [2, 4],
    [3, 3], [3, 4],
    [4, 3], [4, 4], [4, 5],
    ...
  ];
  
  my $s = new Statistics::Suggest(
    RType => 2,
    NNbr => 40,
    Alpha => 0.3,
  );
  $s->load_trans($data);
  $s->init;

  ## make top 10 recommendations for $selected_item_ids
  my $rcmds;
  my $selected_item_ids = [1, 2];
  $s->top_n($selected_item_ids, 10, \$rcmds)
  
  print "recommendations: " . join(',', @$rcmds);

=head1 DESCRIPTION

This is a perl binding for SUGGEST.
Please refer to the SUGGEST's manual for details. Basically,
this package contains all corresponding methods for functions described
in the manual.

=head2 new

  my $s = new Statistics::Suggest(
    # parameters for Init function (see SUGGEST's manual p.5)
    RType => 2,
    NNbr => 40,
    Alpha => 0.3,
  );

=head2 load_trans

Loads user-item transactions that will be used to make recommendations.

  $s->load_trans([
    # [user_id, item_id], ...
    [1, 1], [1, 2], [1, 4],...
  ]);

=head2 estimate_alpha

C<Alpha> parameter can be set automatically by calling C<estimate_alpha> method
after C<load_trans>, before calling C<init>.

  $s->estimate_alpha;


=head2 init

Initializes the SUGGEST engine. Should be called after all transactions are loaded
via C<load_trans> method.

  $s->init;

=head2 top_n

Returns top-n recommendations for the given item set. Should be called after C<init>.

  my $rcmds;
  $s->top_n(
    [3, 4, 5, ... ], # array of item_ids in the user's basket
    10, # number of recommendations required
    \$rcmds, # reference of an array reference for storing recommendations
  );
  print join(',', @$rcmds);


=head2 EXPORT

None by default.

=head1 SEE ALSO

http://glaros.dtc.umn.edu/gkhome/suggest/overview

=head1 AUTHOR

Ikuhiro IHARA E<lt>tsukue@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Ikuhiro IHARA

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
