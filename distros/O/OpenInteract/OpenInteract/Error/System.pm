package OpenInteract::Error::System;

# $Id: System.pm,v 1.9 2002/04/13 16:10:06 lachoy Exp $

use strict;
use Carp                   qw( cluck );
use Data::Dumper           qw( Dumper );
use OpenInteract::Error::Main;
use OpenInteract::Utility;
use SPOPS::Utility;

@OpenInteract::Error::System::ISA     = ();
$OpenInteract::Error::System::VERSION = sprintf("%d.%02d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/);

my $ERROR_HOLD = $OpenInteract::Error::Main::ERROR_HOLD;

# Increment at which we should break down
# codes if not found (change to 100 for more macro)

my $CODE_SEEK = 10;

# Match up codes with the actual handler

$OpenInteract::Error::System::CODES = {
     '-1'  => \&log_and_return,
     '0'   => \&log_and_return,
     '10'  => \&cannot_parse_config,
     '11'  => \&cannot_connect_db,
     '100' => \&log_and_return,
     '200' => \&log_and_return,
     '201' => \&cannot_open_template,
     '202' => \&cannot_parse_template,
     '203' => \&cannot_send_mail,
     '204' => \&cannot_open_template_db,
     '205',=> \&cannot_find_login_fields,
     '300' => \&log_and_return,
     '301' => \&file_not_found,
     '302' => \&cannot_log_object_creation,
     '303' => \&task_is_forbidden,
     '304' => \&task_no_default,
     '305' => \&task_not_allowed_security,
     '307' => \&cannot_retrieve_object_of_id,
     '308' => \&log_and_return,
     '309' => \&log_and_return,
     '310' => \&cannot_create_session,
     '311' => \&log_and_return,
     '312' => \&log_and_return,
     '313' => \&log_and_return,
     '314' => \&file_not_found,
     '400' => \&log_and_return,
     '401' => \&bad_username,
     '402' => \&bad_password,
     '403' => \&cannot_fetch,
     '404' => \&cannot_fetch,
     '405' => \&log_and_return,
     '406' => \&log_and_return,
     '407' => \&log_and_return,
     '500' => \&log_and_return,
     '600' => \&log_and_return,
     '700' => \&log_and_return,
     '800' => \&log_and_return,
     '900' => \&log_and_return,
};

# Since we can handle any code, we move the checking phase to the error handler

sub can_handle_error {
    my ( $class, $err ) = @_;

    # Just find the general handler for that particular code. Here's an
    # example of how we find a code:
    # Original code: 512
    #  1) 512 -> not found -> 510
    #  2) 510 -> not found -> 500

    my $start = $CODE_SEEK;
    my $info = $OpenInteract::Error::System::CODES->{ $err->{code} };
    while ( ! $info ) {
        my $use_code = $err->{code} - ( $err->{code} % $start );
        $start *= 10;
        $info = $OpenInteract::Error::System::CODES->{ $use_code };
    }
    return $info;
}


#000

sub cannot_parse_config {
    my ( $err ) = @_;
    my $R = OpenInteract::Request->instance;
    $R->DEBUG && cluck ">> Error: Cannot open/parse config file.",
                       "$err->{tmp_filename} / $err->{system_msg}";
    $err->{notes} = "Filename tried to open: $err->{tmp_filename}";
    OpenInteract::Error::Main->save_error( $err );
    return '<h2 align="center">Website Down</h2>' .
           '<p>This website is currently down for technical reasons. Please come back shortly ' .
           'and we will surely have this configuration problem licked.';
}


# Since the db is down, we need to bypass the normal saving mechanisms
# and save the object by hand. We generate the ID here since it's
# normally done by the $err->save call.

sub cannot_connect_db {
    my ( $err ) = @_;
    my $R = OpenInteract::Request->instance;
    $R->DEBUG &&  cluck ">> Error: Cannot connect to db. Info:\n",
                        Dumper( $err->{tmp_db_info} ) ;
    my $C = $R->CONFIG;
    $err->{error_id} = SPOPS::Utility->generate_random_code( 16 );

    # First send an email

    my $msg = <<MSG;

Website Name: $C->{server_info}{website_name}

Something terrible has happened: I cannot connect to
the database or a previous connection has been dropped.
If you do not fix this soon, you will have an angry
mob of users on your hands.

 Error Code: $err->{error_id}
 (written out to $R->{dir}{base}/error)

Your friendly OpenInteract System
MSG
    my $send_to = $R->CONFIG->{mail}{admin_email} ||
                  $R->CONFIG->{admin_email};
    eval { OpenInteract::Utility->send_email({ to      => $send_to,
                                               message => $msg,
                                               subject => 'Cannot connect to database!' }) };
    if ( $@ ) {
        $err->{notes} = "Cannot send email to admin; saved email msg";
        $R->throw({ code => 203 });
    }
    else {
        $err->{notes} = 'E-mail sent to admin ok.';
    }
    $err->{notes} = "DB connection info:", Dumper( $err->{tmp_db_info} );
    $err->fail_save;
    return '<h2 align="center">Website Down</h2>' .
           '<p>This website is currently down for technical reasons. Please come back shortly ' .
           'and we will surely have this database problem licked.';
}


#100


#200

sub cannot_open_template {
    my ( $err ) = @_;
    my $R = OpenInteract::Request->instance;
    $R->DEBUG && cluck ">> Error: cannot open template.",
                       "$err->{tmp_filename} / $err->{system_msg}";
    $err->{user_msg} = 'Could not open template file';
    $err->{notes} = "Filename tried to open: $err->{tmp_filename}";
    OpenInteract::Error::Main->save_error( $err );
    return undef;
}


sub cannot_parse_template {
    my ( $err ) = @_;
    my $R = OpenInteract::Request->instance;
    $R->DEBUG && cluck ">> Error: cannot parse template.",
                       "$err->{tmp_filename} / $err->{system_msg}";
    $err->{user_msg} = 'Could not process template';
    $err->{notes} = "Filename tried to open: $err->{tmp_filename} (if blank, we used text passed in)";
    OpenInteract::Error::Main->save_error( $err );
    return "[[ error processing directive: template error ]]";
}


sub cannot_send_mail {
    my ( $err ) = @_;
    my $mail_info = $OpenInteract::Error::extra;
    OpenInteract::Error::Main->save_error( $err );
    my $R = OpenInteract::Request->instance;
    my $filename = $R->CONFIG->get_dir( 'mail' ) . "/msg_$err->{error_id}";
    eval { open( MAIL, "> $filename" ) || die $! };
    if ( $@ ) {
        $R->scrib( 0, "Good gravy! I cannot send an email, and I cannot open up a file to dump\n",
                      "the email into. (Tried: (($filename)) and got (($@)) in return.)\n",
                      "I'll just put it into STDERR and you can deal with it.\n\n", Dumper( $mail_info ), "\n" );
        return undef;
    }
    print MAIL "To: $mail_info->{to}\n",
               "From: $mail_info->{from}\n",
               "Subject: $mail_info->{subject}\n\n",
               $mail_info->{message}, "\n\n";
    close( MAIL );
    return undef;
}



sub cannot_open_template_db {
    my ( $err ) = @_;
    my $R = OpenInteract::Request->instance;
    $R->DEBUG && cluck ">> Error: cannot open template.",
                       "$err->{tmp_name} / $err->{system_msg}";
    $err->{user_msg} = 'Could not open template from database';
    $err->{notes} = "Tag tried to open with: $err->{tmp_name}";
    OpenInteract::Error::Main->save_error( $err );
    return undef;
}


sub cannot_find_login_fields {
    my ( $err ) = @_;
    my $R = OpenInteract::Request->instance;
    $R->DEBUG && cluck ">> Error: cannot find login/password fields!";
    $err->{user_msg}   = 'No login/password fields specified!';
    $err->{system_msg} = "Please create entries in your 'conf/server.perl' file under " .
                         "the 'login->login_field' and 'login->password_field' keys. I cannot " .
                         "process logins until this is done. Remember to restart the server after " .
                         "you have made the change.";
    OpenInteract::Error::Main->save_error( $err );
    return undef;
}


#300

# Syntax: $R->throw({ code => 314, system_msg => '/location/notfound' });

sub file_not_found {
    my ( $err ) = @_;
    my $R = OpenInteract::Request->instance;
    $R->DEBUG && cluck ">> Error: cannot find or open requested location *$err->{system_msg})";
    $err->{user_msg} = 'Requested file not found or cannot be opened';
    OpenInteract::Error::Main->save_error( $err );
    $R->{page}{title} = 'Sorry: Not found';
    my $html = $R->template->handler( {}, { err => $err },
                                      { name => 'error_not_found' } );
    die "$html\n";
}


sub cannot_log_object_creation {
    my ( $err ) = @_;
    OpenInteract::Error::Main->save_error( $err );
    return undef;
}


sub task_is_forbidden {
    my ( $err ) = @_;
    my $R = OpenInteract::Request->instance;
    $R->DEBUG && cluck ">> Error: Cannot perform task due to security ($err->{system_msg})";
    my $html = $R->template->handler( {},
                                      { err => $err,
                                        admin_email => $R->CONFIG->{mail}{admin_email} ||
                                                       $R->CONFIG->{admin_email} },
                                      { name => 'error_task_forbidden' } );
    die "$html\n";
}


sub task_no_default {
    my ( $err ) = @_;
    my $R = OpenInteract::Request->instance;
    $err->{user_msg} = 'No default method defined';
    $R->DEBUG && cluck ">> Error: Cannot do task due to no default: $err->{system_msg}";

    # First send an email

    eval { OpenInteract::Utility->send_email({ to      => $err->{tmp_email},
                                               message => $err->{tmp_msg},
                                               subject => $err->{tmp_subject} }) };
    if ( $@ ) {
        $err->{notes} = "Cannot send email to author; saved email msg";
        $R->throw({ code => 203 });
    }
    else {
        $err->{notes} = 'E-mail sent to author ok.';
    }
    OpenInteract::Error::Main->save_error( $err );
    my $html = $R->template->handler( {},
                                      { err => $err,
                                        author_email => $err->{tmp_email} },
                                      { name => 'error_task_no_default' } );
    die "$html\n";
}


sub task_not_allowed_security {
    my ( $err ) = @_;
    my $R = OpenInteract::Request->instance;
    $R->DEBUG && cluck ">> Error: Cannot accomplish task due to security.";
    my $html = $R->template->handler( {},
                                      { err => $err,
                                        admin_email => $R->CONFIG->{mail}{admin_email} ||
                                                       $R->CONFIG->{admin_email}  },
                                      { name => 'error_task_forbidden' } );
    die "$html\n";
}


sub cannot_retrieve_object_of_id {
    my ( $err ) = @_;
    my $R = OpenInteract::Request->instance;
    $R->DEBUG && cluck ">> Error: Cannot retrieve object given a particular ID.";

    # First send an email

    my $msg = <<'';
For some reason beyond security, a user could not retrieve an object
given a particular ID. You might want to look into it.

    eval { OpenInteract::Utility->send_email({ to      => $R->CONFIG->{mail}{admin_email} || 
                                                          $R->CONFIG->{admin_email},
                                               message => $msg,
                                               subject => 'Failed to retrieve object' }) };
    if ( $@ ) {
        $err->{notes} = "Cannot send email to admin; saved email msg";
        $R->throw( { code => 203 } );
    }
    else {
        $err->{notes} = 'E-mail sent to admin ok.';
    }
    OpenInteract::Error::Main->save_error( $err );
    return undef;
}


sub cannot_create_session {
    my ( $err ) = @_;
    my $R = OpenInteract::Request->instance;
    $R->scrib( 0, "Cannot create session -- someone is probably using a ",
                  "defunct key or something." );
    $R->cookies->create_cookie({
                   name => $OpenInteract::Session::COOKIE_NAME,
                   path => '/',
                   value => undef,
                   expires => '-3d' });
    return log_and_return( $err );
}


#400

sub bad_username {
    my ( $err ) = @_;
    my $R = OpenInteract::Request->instance;
    $R->DEBUG && cluck ">> Error: User $err->{tmp_login_name} not found in system";
    $R->{ $ERROR_HOLD }{loginbox}{bad_login} = "User $err->{tmp_login_name} not found!";
    return undef;
}

sub bad_password {
    my ( $err ) = @_;
    my $R = OpenInteract::Request->instance;
    $R->DEBUG && cluck ">> Error: User $err->{tmp_login_name} login with wrong password";
    $R->{ $ERROR_HOLD }{loginbox}{bad_login}  = "Bad password for $err->{tmp_login_name}; try again.";
    $R->{ $ERROR_HOLD }{loginbox}{login_name} = $err->{tmp_login_name};
    return undef;
}


sub cannot_fetch {
    my ( $err ) = @_;
    if ( $err->{code} == 403 ) {
        cluck ">> Error thrown for not being able to fetch a group of objects. Msg: $err->{system_msg}";
    }
    elsif ( $err->{code} == 404 ) {
        cluck ">> Error thrown for not being able to fetch an object. Msg: $err->{system_msg}";
    }
    return log_and_return( $err, 'nowarn' );
}

#500


#600


#700



#Generic

sub log_and_return {
    my ( $err, $opt ) = @_;
    my $R = OpenInteract::Request->instance;
    cluck ">> Error with code $err->{code} thrown. Info: $err->{system_msg}" unless ( $opt eq 'nowarn' );
    $R->DEBUG && $R->scrib( 2, "Trying to save errror ", Dumper( $err ) );
    OpenInteract::Error::Main->save_error( $err );
    return undef;
}

1;

__END__

=pod

=head1 NAME

OpenInteract::Error::System - Catalog of system error handlers

=head1 SYNOPSIS

 $R->throw( { code => 302, type => 'module' } );

=head1 DESCRIPTION

=head1 ERROR CODES

Following is a (hopefully) exhaustive list of errors generated by the
base OpenInteract modules. Note that the base OpenInteract modules
should not generate errors with codes greater than 25 in their range
(e.g., greater than than 425 in the 400 - 499 range).

This means that you as an application developer are free to create
your own error handlers to respond to errors in the x25 - x99
range. This also means that you should never create an error handler
that responds to an error less than 25 in a range unless you are
explicitly overriding a system error handler. Otherwise there will
eventually be a conflict, which would be bad.

B<0-100>: emerg - system is unusable

=over 4

=item *

10: cannot_parse_config

=item *

11: cannot_connect_db

=back

B<100-199>: alert - action must be taken immediately

=over 4

=item *

(none currently)

=back

B<200-299> crit - critical conditions

=over 4

=item *

201: cannot_open_template

=item *

202: cannot_parse_template

=item *

203: cannot_send_mail

=item *

204: cannot_open_template_db

=item *

205: cannot_find_login_fields

=back

B<300-399> err - error conditions

=over 4

=item *

301: file_not_found

=item *

302: cannot_log_object_creation

=item *

303: task_is_forbidden

=item *

304: task_no_default

=item *

305: task_not_allowed_security

=item *

306: cannot_retrieve_object_updates

=item *

307: cannot_retrieve_object_of_id

=item *

308: cannot_check_security_on_object

=item *

309: cannot_retrieve_groups_for_user

=item *

310: cannot_create_session

=item *

311: cannot_retrieve_user_for_authentication

=item *

312: cannot_run_module

=item *

312: required_parameter_not_found

=item *

313: cannot_open_static_file

=back

B<400-499> warning - warning conditions

=over 4

=item *

401: bad_username

=item *

402: bad_password

=item *

403: cannot_retrieve_object_listing

=item *

404: cannot_retrieve_object (non-security)

=item *

405: cannot_remove_object (non-security)

=item *

406: cannot_set_security

=item *

407: cannot_save_object (non-security)

=back

B<500-599>: notice - normal but significant condition

=over 4

=item *

(none currently)

=back

B<600-699> info - informational

=over 4

=item *

(none currently)

=back

B<700-799> debug - debug-level messages

=over 4

=item *

(none currently)

=back

B<800-999> user-defined - whatever you wish them to be; no base
OpenInteract modules will generate errors in this range

=head1 METHODS

Methods are all attached to various error codes.

=head1 TO DO

Nothing.

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>

=cut
