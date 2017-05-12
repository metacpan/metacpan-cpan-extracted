package VCP::UI ;

=head1 NAME

VCP::UI - User interface framework for interactive mode VCP.

=head1 SYNOPSIS

    $ vcp

=head1 DESCRIPTION

When VCP is run with no source or destination specifications, it loads
and launches an interactive user interface.

The current default is a text user interface, but this may change
to be a graphical UI on some platforms in the future.

=head1 METHODS

=over

=cut

$VERSION = 0.1 ;

use strict ;

use fields (
   'UI',     # The VCP::UI::* to use
) ;


=item new

   my $ui = VCP::UI->new;

=cut

sub new {
   my $class = shift ;
   $class = ref $class || $class;

   my VCP::UI $self = do {
      no strict 'refs' ;
      bless [ \%{"$class\::FIELDS"} ], $class;
   };

   %$self = @_;

   return $self ;
}

=item run

Runs the UI.  Selects the appropriate user interface (unless one has
been passed in) and runs it.

=cut

sub run {
    my VCP::UI $self = shift;

    $self->{UI} = "VCP::UI::Text"
        unless defined $self->{UI};

    unless ( ref $self->{UI} ) {
        eval "require $self->{UI}" or die "$@ loading $self->{UI}";
    }

    $self->{UI}->new->run;

    1;
}


=back

=head1 COPYRIGHT

Copyright 2000, Perforce Software, Inc.  All Rights Reserved.

This module and the VCP::UI package are licensed according to the terms given in
the file LICENSE accompanying this distribution, a copy of which is included in
L<vcp>.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1
