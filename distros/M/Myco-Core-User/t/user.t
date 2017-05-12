# $Id: user.t,v 1.1.1.1 2006/03/01 21:00:55 sommerb Exp $

=pod

=head1 NAME

user.t - Myco::Core::User tests

=cut

use strict;
use warnings;
use lib 'lib';
use lib '../myco_core_person/lib';
use Myco::Core::User;
use Myco::Core::Person;
use sigtrap qw(BUS SEGV);

use Test::More;
BEGIN { plan tests => 21 };

my $class = 'Myco::Core::User';

sub test_person {
  my $p = Myco::Core::Person->new( first => 'Jim-Bob', last => 'Lancelot',
				   prefix => 'Sir' );
#  $p->save;

  return $p;
};

sub test_user {
  my $u = Myco::Core::User->new( login => 'larry',
				 pass  => 'Knnnnnnnnn-igits!',
				 person => test_person() );
  return $u;
}

# Create closure that knows how to clean up the mess
sub test_cleanup {
  my $u_ = Myco->remote('Myco::Core::User');
  my $p_ = Myco->remote('Myco::Core::Person');
  my (@p) = Myco->select( $p_, $p_->{last} eq 'Lancelot' &
			       $p_->{first} eq 'Jim-Bob', );
  Myco->destroy(@p);

  my @u = Myco->select( $u_, $u_->{login} eq 'larry' );
  Myco->destroy(@u);

}


##############################################################################
# Now test the login with a user logged in.
sub test_login_access {
    my $test = shift;
    ok( my $u = &test_user, "Get $class object" );
    $u->add_roles('admin');

    ok($u->get_login eq 'larry', 'Login is "larry"');
    $u->set_login('czbsd');
    ok($u->get_login eq 'czbsd', 'Login czbsd');
}

##############################################################################
# Test password attribute.
sub test_pass {
    ok( my $u = &test_user,
                   "Get $class object" );
    ok($u->chk_pass('Knnnnnnnnn-igits!'),
                  'First password check');
    ok(! $u->chk_pass('bogus password'),
                  'Bogus password check');
    $u->set_pass('Aaaaaa....herring!');
    ok(! $u->chk_pass('Knnnnnnnnn-igits!'),
                  'New bogus password check');
    ok($u->chk_pass('Aaaaaa....herring!'),
                  'Successful new password check');
    eval { $u->pass };
    ok($@ && $@ =~ /^unknown method/, 'pass() dies');
    $@ = undef;
    eval { $u->get_pass };
    ok($@ && $@ =~ /^unknown method/, 'get_pass() dies');
}

##############################################################################
# Test password attribute with user logged in.
sub test_pass_access {
    ok( my $u = &test_user,
                   "Get $class object" );
    $u->add_roles('admin');

    ok($u->chk_pass('Knnnnnnnnn-igits!'),
		  'First password check');
    ok(! $u->chk_pass('bogus password'),
		  'Bogus password check');
    $u->set_pass('Aaaaaa....herring!');
    ok(! $u->chk_pass('Knnnnnnnnn-igits!'),
		  'New bogus password check');
    ok($u->chk_pass('Aaaaaa....herring!'),
		  'Successful new password check');
    eval { $u->pass };
    ok($@ && $@ =~ /^unknown method/, 'pass() dies');
    $@ = undef;
    eval { $u->get_pass };
    ok($@ && $@ =~ /^unknown method/, 'get_pass() dies');

}

##############################################################################
# Test person attribute with user logged in.
sub test_person_access {
    ok( my $u = &test_user,
                   "Get $class object" );

    $u->add_roles('admin');

    ok( my $p = $u->get_person, "Get person" );
    ok( UNIVERSAL::isa($p, 'Myco::Core::Person'),
		   "It's a person!" );
    ok( $p->get_prefix eq 'Sir',
                   "You are a knight of the round table?" );
}

##############################################################################
# Test access checking in Entity.pm. Start with set().

#
# DISABLED while ::Entity::set/get is disabled
#
sub _test_set_access {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    # Okay, save the existing user class access roles so we can restore them
    # at the end of this method. The reason we're using our own here is so
    # that we can have fine control over testing both class-level and
    # attribute-level access roles.
    my $md = $class->introspect;
    my $apiroles = _save_class_roles($md);

    # Set up the user with some roles and make sure that he's the current
    # user.
    ok( my $u = &test_user,
                   "Get $class object" );
    $u->set_roles(qw(master));

    Myco::UI::Auth->_set_current_user($u);
    # (You didn't see that.)

    # Only the rw permissions are checked for get().
    $md->set_access_list( { rw => ['master'] });

    # Okay now, try to do something to $u. Because Lancelot is the current
    # user, and he's a member of the "master" role, and the Myco::Core::User class
    # allows that role to have read/write access, Lancelot should have no
    # problems.
    $u->set_login('foober');
    ok($u->get_login eq 'foober', "Cool, the access was granted!");

    # Okay, now deny access. Start by removing the role from Lancelot and giving
    # him another role. set_roles() will replace existing roles.
    $u->set_roles('servant');
    # Now just eval an access.
    eval { $u->set_login('arrgghh') };
    # Yes, Test::Unit really *is* that retarded.
    my $err = $@ && $@ =~ /You do not have permission to edit/;
    _restore_class_roles($md, $apiroles) unless $err; # Rollback!
    ok($err, "Deeeeeenied!" );

    # Now, let's try attribute permissions.
    my $la = $md->get_attributes->{login};
    # Sanity checks.
    ok( UNIVERSAL::isa($la, "Myco::Base::Entity::Meta::Attribute"),
                   "Yes, it's an attribute");
    ok( $la->get_name eq 'login', "Yes, it's the login attribute" );

    # Eliminate the class-level access list.
    $md->set_access_list({});
    # Only the rw permissions are checked for get().
    $la->set_access_list( { rw => ['master'] });

    # Return the user to that role.
    Myco::UI::Auth->_set_current_user(undef);
    $u->add_roles('master');
    Myco::UI::Auth->_set_current_user($u);
    # (More stuff you didn't see.)

    # Test it!
    $u->set_login('foober');
    ok($u->get_login eq 'foober',
                  "Cool, the attr access was granted!");

    # Now deny them access. Remove them from the master role. Give 'em another
    # role just for the hell of it.
    $u->set_roles('servant');
    eval { $u->set_login('arrgghh') };
    $err = $@ && $@ =~ /You do not have permission to edit the/;
    _restore_class_roles($md, $apiroles) unless $err; # Rollback!
    ok($err, "Deeeeeenied attr!" );

    # Clean up our mess.
    Myco::UI::Auth->_set_current_user(undef);
    # (You didn't see that, either.)

    # Restore roles assigned by class.
    _restore_class_roles($md, $apiroles);
}

##############################################################################
# Now test get() access checking in Entity.pm.

#
# DISABLED while ::Entity::set/get is disabled
#
sub _test_get_access {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    # Okay, save the existing user class access roles so we can restore them
    # at the end of this method. The reason we're using our own here is so
    # that we can have fine control over testing both class-level and
    # attribute-level access roles.
    my $md = $class->introspect;
    my $apiroles = _save_class_roles($md);

    # Set up the user with some roles and make sure that he's the current
    # user.
    ok( my $u = &test_user,
                   "Get $class object" );
    $u->set_roles(qw(master));
    Myco::UI::Auth->_set_current_user($u);
    # (You didn't see that.)

    # Only the rw permissions are checked for get().
    $md->set_access_list( { ro => ['master'] });

    # Okay now, try to do something to $u. Because Lancelot is the current
    # user, and he's a member of the "master" role, and the Myco::Core::User class
    # allows that role to have read/write access, Lancelot should have no
    # problems.
    ok($u->get_login eq 'larry', "Cool, the access was granted!");

    # Access to call set() should be denied, though.
    eval { $u->set_login('foober') };
    my $err = $@ && $@ =~ /You do not have permission to edit/;
    _restore_class_roles($md, $apiroles) unless $err; # Rollback!
    ok($err, "Deeeeeenied set()!" );

    # Okay, now deny access. Start by removing the role from Lancelot and
    # giving him another role. set_roles() will replace existing roles.
    Myco::UI::Auth->_set_current_user(undef);
    $u->set_roles('servant');
    Myco::UI::Auth->_set_current_user($u);
    # More stuff you didn't see!

    # Now just eval an access.
    eval { $u->get_login };
    $err = $@ && $@ =~ /You do not have permission to read/;
    _restore_class_roles($md, $apiroles) unless $err; # Rollback!
    ok($err, "Deeeeeenied get()!" );

    # Setting still shouldn't be possible.
    eval { $u->set_login('arrgghh') };
    $err = $@ && $@ =~ /You do not have permission to edit/;
    _restore_class_roles($md, $apiroles) unless $err; # Rollback!
    ok($@, "Deeeeeenied set() again!" );

    # Now, let's try attribute permissions.
    my $la = $md->get_attributes->{login};
    # Sanity checks.
    ok( UNIVERSAL::isa($la, "Myco::Base::Entity::Meta::Attribute"),
                   "Yes, it's an attribute");
    ok( $la->get_name eq 'login', "Yes, it's the login attribute" );

    # Fake out an attribute role.
    $md->set_access_list({});
    my $attr_old_roles = $la->get_access_list;
    # Only the rw permissions are checked for get().
    $la->set_access_list( { ro => ['master'] });

    # Return the user to that role.
    Myco::UI::Auth->_set_current_user(undef);
    $u->add_roles('master');
    Myco::UI::Auth->_set_current_user($u);
    # (More stuff you didn't see.)

    # Test it
    ok($u->get_login eq 'larry',
                  "Cool, the access was granted again!");

    # Setting still shouldn't be possible.
    eval { $u->set_login('arrgghh') };
    $err = $@ && $@ =~ /You do not have permission to edit the/;
    _restore_class_roles($md, $apiroles) unless $err; # Rollback!
    ok($err, "Deeeeeenied set attr!" );

    # Now deny them access. Remove them from the master role. Give 'em another
    # role just for the hell of it.
    $u->set_roles('servant');
    eval { $u->get_login };
    $err = $@ && $@ =~ /You do not have permission to read the/;
    _restore_class_roles($md, $apiroles) unless $err; # Rollback!
    ok($err, "Deeeeeenied get() again!" );

    # Setting *still* shouldn't be possible.
    eval { $u->set_login('arrgghh') };
    $err = $@ && $@ =~ /You do not have permission to edit the/;
    _restore_class_roles($md, $apiroles) unless $err; # Rollback!
    ok($err, "Deeeeeenied get() again!" );

    # Clean up our mess.
    Myco::UI::Auth->_set_current_user(undef);
    # (You didn't see that, either.)

    # Restore roles assigned by class.
    _restore_class_roles($md, $apiroles);
}

##############################################################################
# Persistent Tests.
##############################################################################
sub test_auth {
    # First, save the user.
    ok( my $u = &test_user,
                   "Get $class object" );
    ok( my $id = $u->save, "Save user" );

    # update person obj so its user's ref in 'stuff' is saved
    my $p = $u->get_person;
    $p->save;

    # Now remove the user from memory.
    Myco->unload($u, $p);
    ok(! Myco->is_transient($id), "User not transient" );
    undef $u;
    undef $p;

    # Now instantiate the user by looking it up by login.
    my $u_r = Myco->remote('Myco::Core::User');
    ($u) = Myco->select($u_r, $u_r->{login} eq 'larry');

    # Check the password.
    ok( $u->chk_pass('Knnnnnnnnn-igits!'), "Validate password." );

    # Scheduled deletion via erasure of Person owning this User obj
    test_cleanup();
}

##############################################################################
# Test user roles.
sub test_roles {
    ok( my $u = &test_user,
                   "Get $class object" );
    $u->set_roles( qw(master));
    $u->add_roles( qw(servant admin));
    my $roles = $u->get_roles;
    ok( ref $roles eq 'ARRAY', "Roles are an array" );
    ok( $#$roles == 2, "Correct number of roles" );
    ok( $roles->[0] eq 'admin', "Admin is present" );
    ok( $roles->[1] eq 'master', "Master is present" );
    ok( $roles->[2] eq 'servant', "Servant is present" );

    ok( my $id = $u->save, "Save user" );

    # update person obj so its user's ref in 'stuff' is saved
    my $p = $u->get_person;
    $p->save;

    # Now remove the user from memory.
    Myco->unload($u, $p);
    ok(! Myco->is_transient($id), "User not transient" );
    undef $u;
    undef $p;
    undef $roles;

    # Now instantiate the user by looking it up by login.
    my $u_r = Myco->remote('Myco::Core::User');
    ($u) = Myco->select($u_r, $u_r->{login} eq 'larry');

    # Check the roles.
    $roles = $u->get_roles;
    ok( ref $roles eq 'ARRAY', "Roles are still an array" );
    ok( $#$roles == 2, "Correct number of roles after save" );
    ok( $roles->[0] eq 'admin', "Admin is present after save" );
    ok( $roles->[1] eq 'master', "Master is present after save" );
    ok( $roles->[2] eq 'servant', "Servant is present after save" );

    # Try deleting a role, etc.
    $u->del_roles('admin');
    $roles = $u->get_roles;
    ok( $#$roles == 1, "Correct number of roles after delete" );
    ok( $roles->[0] eq 'master', "Master is present after delete" );
    ok( $roles->[1] eq 'servant', "Servant is present after delete" );

    # Save it again and make sure we get it all back again!
    $u->save;
    ($u) = Myco->select($u_r, $u_r->{login} eq 'larry');
    $roles = $u->get_roles;
    ok( $#$roles == 1,
                   "Correct number of roles after delete and save" );
    ok( $roles->[0] eq 'master',
                   "Master is present after delete and save" );
    ok( $roles->[1] eq 'servant',
                   "Servant is present after delete and save" );

    # And finally, get them as objects.
    $u->set_roles(qw(master));
    my ($role) = $u->get_role_objs;
    ok( $role->get_name eq 'master', "Name is 'master'" );
    ok( $role->get_disp_name eq 'Master',
                   "Display Name is 'Master'" );

    # Scheduled deletion via erasure of Person owning this User obj
    test_cleanup();
}

##############################################################################
# Trying to get this sucker to segfault.
sub test_segfault {
    # First, save the user.
    ok( my $u = &test_user,
                   "Get $class object" );
    my $p = $u->get_person;
    $p->set_middle('segfault');

    # we're expecting $p to be in DB
    ok( $p->is_transient, '$p in db' );
    ok( my $id = $u->save, 'Save user' );
    ok( $id, "reasonable obj id" );

    # Update state
    $p->save;

    # Now remove the user from memory.
    Myco->unload($u, $p);
    ok(! Myco->is_transient($id), "Remove user from memory" );
    undef $u;
    undef $p;

    # Now instantiate the user by looking it up by login.
    my $u_r = Myco->remote('Myco::Core::User');
    ($u) = Myco->select($u_r, $u_r->{login} eq 'larry');
    # Make sure that we've loaded the person, too.
    ok($u->get_person->get_middle eq 'segfault',
                  "Check middle name" );

    # Clean up our mess.
    test_cleanup();
}

##############################################################################
# Utility methods.
##############################################################################

##############################################################################
sub _save_class_roles {
    my $md = shift; #$class->introspect;
    my %apiroles = ( "User Roles" => $md->get_access_list );
    my $attrs = $md->get_attributes;
    while (my ($k, $v) = each %$attrs) {
        $apiroles{$k} = $v->get_access_list;
        $v->set_access_list({});
    }
    return \%apiroles;
}

##############################################################################
sub _restore_class_roles {
    my ($md, $apiroles) = @_;
    $md->set_access_list($apiroles->{"User Roles"});
    my $attrs = $md->get_attributes;
    while (my ($k, $v) = each %$attrs) {
        $v->set_access_list($apiroles->{$k});
    }
}

#
#
#  run the tests!!!!!
#
#

&test_login_access;
&test_pass;
&test_pass_access;
&test_person_access;

# we don't want to test persistence for CPAN distribution
#&test_auth;
#&test_roles;
#&test_segfault;


1;
__END__

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

David Wheeler <david@wheeler.net> and Ben Sommer <ben@mycohq.com>

=head1 SEE ALSO

L<Myco::Core::User|Myco::Core::User>

=cut
