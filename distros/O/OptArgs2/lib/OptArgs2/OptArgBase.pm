package OptArgs2::OptArgBase;
use strict;
use warnings;

### START Class::Inline ### v0.0.1 Wed Dec  3 12:04:29 2025
require Carp;
our ( @_CLASS, $_FIELDS, %_NEW );

sub _NEW {
    CORE::state $fix_FIELDS = do {
        $_FIELDS = { @_CLASS > 1 ? @_CLASS : %{ $_CLASS[0] } };
        $_FIELDS = $_FIELDS->{'FIELDS'} if exists $_FIELDS->{'FIELDS'};
    };
    if ( my @missing = grep { not exists $_[0]->{$_} } 'comment', 'name' ) {
        Carp::croak( 'OptArgs2::OptArgBase required initial argument(s): '
              . join( ', ', @missing ) );
    }
    map { delete $_[1]->{$_} } 'comment', 'default', 'encoding', 'getopt',
      'name', 'required', 'show_default';
}

sub __RO {
    my ( undef, undef, undef, $sub ) = caller(1);
    Carp::confess("attribute $sub is read-only");
}
sub comment { __RO() if @_ > 1; $_[0]{'comment'} // undef }
sub default { __RO() if @_ > 1; $_[0]{'default'} // undef }

sub encoding {
    __RO() if @_ > 1;
    $_[0]{'encoding'} //= $_FIELDS->{'encoding'}->{'default'};
}
sub getopt       { __RO() if @_ > 1; $_[0]{'getopt'}       // undef }
sub name         { __RO() if @_ > 1; $_[0]{'name'}         // undef }
sub required     { __RO() if @_ > 1; $_[0]{'required'}     // undef }
sub show_default { __RO() if @_ > 1; $_[0]{'show_default'} // undef }
@_CLASS = grep 1,    ### END Class::Inline ###
  abstract => 1,
  FIELDS   => {
    comment      => { required => 1, },
    default      => {},
    encoding     => { default => ':encoding(UTF-8)' },
    getopt       => {},
    name         => { required => 1, },
    required     => {},
    show_default => {},
  },
  ;

our @CARP_NOT = @OptArgs2::CARP_NOT;

1;

__END__

=head1 NAME

OptArgs2::OptArgBase - A base class for arguments and options

=head1 SYNOPSIS

  use OptArgs2::Opt;
  use parent 'OptArgs2::OptArgBase';

=head1 DESCRIPTION

The C<OptArgs2::OptArgBase> class is internal to L<OptArgs2>.

=head1 AUTHOR

Mark Lawrence <mark@rekudos.net>

=head1 LICENSE

Copyright 2016-2025 Mark Lawrence <mark@rekudos.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

