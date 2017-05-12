package My::User;

# $Id: User.pm,v 3.3 2004/06/02 00:48:25 lachoy Exp $

use strict;
use SPOPS::Initialize;
use SPOPS::Secure qw( :level :scope );

$My::User::VERSION = sprintf("%d.%02d", q$Revision: 3.3 $ =~ /(\d+)\.(\d+)/);
$My::User::crypt_password = undef;

sub _base_config {
   my $config = {
         user => {
             class        => 'My::User',
             isa          => [ 'My::CommonResources', 'SPOPS::Secure', 'My::Common' ],
             rules_from   => [ 'SPOPS::Tool::DBI::DiscoverField' ],
             field_discover => 'yes',
             field        => [],
             id_field     => 'user_id',
             increment_field => 1,
# Uncomment this for InterBase
#            field_map     => { 'password' => 'user_password' },
             sequence_name => 'sp_user_seq',
             no_insert    => [ 'user_id' ],
             skip_undef   => [ 'password' ],
             no_update    => [ 'user_id' ],
             base_table   => 'spops_user',
             sql_defaults => [],
             alias        => [],
             has_a        => {},
             links_to     => { 'My::Group' => 'spops_group_user' },
             fetch_by     => [ 'login_name' ],
             creation_security => {
                 u => undef,
                 g   => { 3 => 'WRITE' },
                 w   => 'READ',
             },
             track        => { create => 0, update => 1, remove => 1 },
             display      => { url => '/User/show/' },
             name         => sub { return $_[0]->full_name },
             object_name  => 'User',
         }
   };
   return $config;
}


sub config_class {
    require My::Group;
    SPOPS::Initialize->process({ config => [ _base_config(),
                                             My::Group->_base_config ] });
}

&config_class;


sub make_public {
    my ( $self ) = @_;

    # First find the public group
    my $groups = eval { My::Group->fetch_group({ where => 'name = ?',
                                                 value => [ 'public' ] }) };

    # Then add the user to it
    if ( my $public = $groups->[0] ) {
        $self->group_add( [ $public->{group_id} ] );

        # Then ensure the public can see (for now) this user

        $self->set_security({ scope    => SEC_SCOPE_GROUP,
                              scope_id => $public->{group_id},
                              level    => SEC_LEVEL_READ });
    }
    return 1;
}


sub full_name { return join ' ', $_[0]->{first_name}, $_[0]->{last_name}; }


sub check_password {
    my ( $self, $check_pw ) = @_;
    return undef unless ( $check_pw );
    my $exist_pw = $self->{password};
    no strict 'refs';
    my $use_crypt = ${ ref( $self ) . '::crypt_password' };
    if ( $use_crypt ) {
        return ( crypt( $check_pw, $exist_pw ) eq $exist_pw );
    }
    return ( $check_pw eq $exist_pw );
}

1;

__END__

=pod

=head1 NAME

My::User - Create and manipulate SPOPS users.

=head1 SYNOPSIS

  use My::User;
  $user = My::User->new();
  $user->{login_name} = 'blah';
  $user->{password}   = 'blahblah';
  $user->{first_name} = 'B';
  $user->{last_name}  = 'Lah';
  eval { $user->save };
  if ( $@ ) {
      print "Cannot save user: $@\n";
  }

  # Use crypt()ed password
  $My::User::crypt_password = 1;

  # Check the password
  unless ( $user->check_password( $given_password ) ) {
      print "Invalid login!\n";
  }

  # Add this user to the group 'public'
  $user->make_public;

=head1 DESCRIPTION

This has the most basic user properties. Customization will probably
be necessary.

=head1 METHODS

B<full_name()>

Returns the full name -- it is accessed often enough that we just made
an alias for concatenating the first and last names.

B<check_password( $pw )>

Return a 1 if the password matches what is in the database, a 0 if
not.

=head1 TO DO

Nothing known.

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>

=cut
