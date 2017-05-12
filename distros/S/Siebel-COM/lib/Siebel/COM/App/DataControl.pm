package Siebel::COM::App::DataControl;

use strict;
use Moose 2.1604;
use namespace::autoclean 0.25;

extends 'Siebel::COM::App';
our $VERSION = '0.3'; # VERSION

has host       => ( is => 'rw', isa => 'Str', required => 1 );
has enterprise => ( is => 'rw', isa => 'Str', required => 1 );
has lang       => ( is => 'rw', isa => 'Str', required => 1 );
has aom        => ( is => 'rw', isa => 'Str', required => 1 );
has transport =>
  ( is => 'rw', isa => 'Str', required => 0, default => 'TCPIP' );
has encryption =>
  ( is => 'rw', isa => 'Str', required => 0, default => 'none' );
has compression =>
  ( is => 'rw', isa => 'Str', required => 0, default => 'none' );

has connected => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
    required => 0,
    reader   => 'is_connected',
    writer   => '_set_connected'
);

has 'ole_class' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'SiebelDataControl.SiebelDataControl.1'
);

sub _error {

    my $self = shift;

    return ('('
          . $self->get_ole()->GetLastErrCode() . '): '
          . $self->get_ole()->GetLastErrText() );

}

sub BUILD {

    my $self = shift;
    $self->get_ole()->EnableExceptions(1);

}

sub get_conn_str {

    my $self = shift;

    if ( defined( $self->get_lang() ) ) {

        return
            'host="siebel.'
          . $self->get_transport() . '.'
          . $self->get_encryption() . '.'
          . $self->get_compression() . '://'
          . $self->get_host() . '/'
          . $self->get_enterprise() . '/'
          . $self->get_aom()
          . '" Lang="'
          . $self->get_lang() . '"';

    }
    else {

        return
            'host="siebel.'
          . $self->get_transport() . '.'
          . $self->get_encryption() . '.'
          . $self->get_compression() . '://'
          . $self->get_host() . '/'
          . $self->get_enterprise() . '/'
          . $self->get_aom() . '"';

    }

}

override 'login' => sub {

    my $self = shift;

    $self->get_ole()
      ->Login( $self->get_conn_str(), $self->get_user(),
        $self->get_password() );

    $self->_set_connected(1);

};

sub logoff {

    my $self = shift;

    $self->get_ole()->Logoff();

    $self->_set_connected(0);

}

sub DEMOLISH {

    my $self = shift;

    if ( $self->is_connected() ) {

        $self->logoff();

    }

}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Siebel::COM::App::DataControl - Perl extension for access Siebel COM Data Control

=head1 SYNOPSIS

  use feature 'say';
  use Siebel::COM::App::DataControl;
  use TryCatch;

  my $input_file = shift;
  chomp($input_file);

  open( my $input, '<', $input_file ) or die "Cannot read $input_file: $!\n";
  my @lines = <$input>;
  close($input);

  my $app = Siebel::COM::App::DataControl->new(
      {
          user       => 'sadmin',
          password   => 'sadmin',
          host       => 'foobar',
          enterprise => 'SIEBEL',
          lang       => 'ENU',
          aom        => 'eCommunicationsObjMgr_enu'
      }
  );

  try {

      $app->login();

      my $bo = $app->get_bus_object('Account');
      my $bc = $bo->get_bus_comp('Account');

      $bc->activate_field('Location');
      $bc->activate_field('Extension Phone Number');

      foreach my $loc (@lines) {

          chomp($loc);

          $bc->clear_query();
          $bc->set_view_mode();

          $bc->set_search_spec( 'Location', "='$loc'" );
          $bc->query();

          if ( $bc->first_record() ) {

              do {

                  my $val = $bc->get_field_value('Location');
  
                  if ( defined($val) ) {

                      $bc->set_field_value( 'Extension Phone Number', '' );
                      $bc->write_record();

                  }

                  say 'updated';

              } while ( $bc->next_record() )

          }
          else {

              say 'Could not find the account';

          }

      }

  }
  catch {

      die 'Exception: ' . $app->get_last_error();

  }

=head1 DESCRIPTION

Siebel::COM::App::DataControl is a subclass of L<Siebel::COM::App>, providing access to the Siebel COM Data Control environment as well
as additional functionality.

Usually using Data Control is the preferable way to access Siebel with COM, but Siebel COM Data Server has it's advantages. Please check 
L<Siebel::COM::App::DataServer> for more details on that.

This class extends L<Siebel::COM::App> superclass, adding more attributees and methods or overriding the inherited ones as necessary.

=head2 ATTRIBUTES

=head3 host

A string that holds the C<host> part of the connection string of Siebel COM Data Control.

The definition of this attribute during object creation is obligatory.

=head3 enterprise

A string that holds the C<enterprise> part of the connection string of Siebel COM Data Control.

The definition of this attribute during object creation is obligatory.

=head3 lang

A string that holds the language code to be used as part of the connection string of Siebel COM Data Control. This parameter is optional.

=head3 aom

A string that holds the C<AOM> part of the connection string of Siebel COM Data Control.

The definition of this attribute during object creation is obligatory.

=head3 transport

A string that holds the C<transport> part of the connection string of Siebel COM Data Control.

The definition of this attribute during object creation is optional, but defaults to "TCPIP".

=head3 encryption

A string that holds the C<encryption> part of the connection string of Siebel COM Data Control.

The definition of this attribute during object creation is optional, but defaults to "none".

=head3 compression

A string that holds the C<compression> part of the connection string of Siebel COM Data Control.

The definition of this attribute during object creation is optional, but defaults to "none".

=head3 connected

A boolean to indicate if the object instance is connected or not to a Siebel Enterprise.

It is not required during object creation and defaults to false (0). For obvious reasons, one should not use it to instantiate a new object.

This attribute is read-only.

=head3 ole_class

A string represeting the class name to be instantied by L<Win32::OLE>. It defaults to "SiebelDataControl.SiebelDataControl.1" and most 
probably you don't want to change that.

This attribute is read-only.

=head2 METHODS

All attributes defaults to have their getters/setters methods as the same name of the attribute, with some exceptions:

=over

=item *

ole_class is read-only

=item *

connected is read-only. The getter for it is C<is_connected>.

=back

Additionally by those defined by the superclass, this class have the following methods:

=head3 BUILD

Additionally by the superclass C<BUILD>, this methods automatically enables exceptions for errors during usage of Data Control.

=head3 DEMOLISH

This is a Moose based DEMOLISH method. Takes care of invoking C<logoff> if the object it is still connected to a Siebel Enterprise during
object destruction.

=head3 get_conn_str

Returns a formatted string of the connection string used by Siebel COM Data Control to connect to a Siebel Enterprise through COM.

=head3 logoff

Executes the logoff of a Siebel Enterprise. Can be invoked anytime, but it will be invoked by default during object destruction if
C<is_connected> method returns true.

=head2 EXPORT

None by default.

=head1 SEE ALSO

=over

=item *

L<Siebel::COM::App>

=item *

L<Siebel::COM::App::DataServer>

=item *

L<Win32::OLE>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Siebel COM project.

Siebel COM is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel COM is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel COM.  If not, see <http://www.gnu.org/licenses/>.

=cut
