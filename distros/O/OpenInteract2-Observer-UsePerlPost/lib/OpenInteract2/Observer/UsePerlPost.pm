package OpenInteract2::Observer::UsePerlPost;

# $Id: UsePerlPost.pm,v 1.9 2005/01/17 00:06:59 cwinters Exp $

use strict;
use Log::Log4perl            qw( get_logger );
use Net::Blogger;
use OpenInteract2::Constants qw( :log );
use OpenInteract2::Context   qw( CTX DEPLOY_URL );

$OpenInteract2::Observer::UsePerlPost::VERSION  = '0.05';

my $DEFAULT_PROXY = 'http://use.perl.org/journal.pl';
my $DEFAULT_URI   = 'http://use.perl.org/Slash/Journal/SOAP';

my @REQUIRED_FIELDS = qw(
    use_perl_subject use_perl_content
    use_perl_user_id use_perl_password
);

my ( $log );

sub update {
    my ( $class, $action, $type, $object ) = @_;
    return unless ( $type eq 'post add' );

    my $request = CTX->request;

    my $do_skip = $action->param( 'use_perl_skip' );
    unless ( $do_skip ) {
        if ( $request ) {
            $do_skip = $request->param( 'use_perl_skip' );
        }
    }
    return if ( $do_skip eq 'yes' );

    $log ||= get_logger( LOG_APP );

    my $subject_field = $action->param( 'use_perl_subject' );
    my $content_field = $action->param( 'use_perl_content' );
    my $user_id       = $action->param( 'use_perl_user_id' );
    my $password      = $action->param( 'use_perl_password' );

    my $action_name = $action->name;
    my $error_preamble = "Cannot post use.perl journal from action '$action_name'!";
    unless ( $subject_field and $content_field and $user_id and $password ) {
        $log->error(
            "$error_preamble You must define the following parameters in ",
            "your action: ", join( ', ', @REQUIRED_FIELDS ), ". You can ",
            "do so in the configuration file or in the action code itself."
        );
        return;
    }

    my $subject = $object->$subject_field();
    my $content = $object->$content_field();
    unless ( $subject and $content ) {
        $log->error(
            "$error_preamble No subject found from method '$subject_field' ",
            "or no content found from method '$content_field'; not creating ",
            "journal entry."
        );
        return;
    }

    if ( my $footer = $action->param( 'use_perl_footer' ) ) {
        $content .= "\n\n" . $class->_generate_footer( $object, $footer );
    }

    my $blogger = Net::Blogger->new(
        engine => 'slash',
        debug  => $log->is_debug,
    );

    my $use_perl_proxy = $action->param( 'use_perl_proxy' )
                         || $DEFAULT_PROXY;
    my $use_perl_uri   = $action->param( 'use_perl_uri' )
                         || $DEFAULT_URI;

    # Before we send the content we want to get rid of any HTML that
    # use.perl might not like. (This could be better done...)

    # First create 'ecode' sections...

    $content =~ s|<pre[^>]+>|<ecode>|g;
    $content =~ s|</pre>|</ecode>|g;

    # ...then remove all img tags and replace them with links to the
    # image and a note about what you're seeing

    my @image_tags = $content =~ /(<img[^>]+>)/gsm;
    foreach my $img_tag ( @image_tags ) {
        my ( $src ) = $img_tag =~ /src="([^"]+)"/sm;
        my ( $alt ) = $img_tag =~ /alt="([^"]+)"/sm;
        unless ( $alt ) {
            my $base_src = '';
            if ( $alt =~ m|/| ) {
                ( $base_src ) = $src =~ m|.*/(.*)$|;
            }
            else {
                $base_src = $src;
            }
            $alt = $base_src;
        }
        $content =~ s|$img_tag|(view image: <a href="$src">$alt</a>)|sm;
    }

    my $debug_only = $action->param( 'use_perl_debug' );
    if ( $debug_only =~ /^(yes|true)/i ) {
        $log->warn( "Not sending data to use.perl server since ",
                    "'use_perl_debug' is set." );
        $log->warn( "Proxy: $use_perl_proxy" );
        $log->warn( "Uri: $use_perl_uri" );
        $log->warn( "Username: $user_id" );
        my $masked = join( '', map { 'X' } ( 1 .. length $password ) );
        $log->warn( "Password: $masked (masked)" );
        $log->warn( "Subject:\n$subject" );
        $log->warn( "Body:\n$content" );
    }
    else {
        $blogger->Proxy( $use_perl_proxy );
        $blogger->Uri( $use_perl_uri );
        $blogger->Username( $user_id );
        $blogger->Password( $password );
        my $post_id = $blogger->slash()->add_entry(
            subject => $subject,
            body    => $content,
        );
        $log->is_info &&
            $log->info( "Result from adding entry '$subject': $post_id" );
    }
}

sub _generate_footer {
    my ( $class, $object, $footer ) = @_;
    if ( $footer =~ /\$LINK/ || $footer =~ /\$ID/ ) {
        my ( $object_info, $object_url, $object_id );
        eval {
            $object_info = $object->object_description;
            $object_url  = $object_info->{url};
            $object_id   = $object_info->{object_id};
        };

        # last-ditch to define the ID
        eval {
            $object_id ||= $object->id
        };

        if ( $object_url ) {
            my $request = CTX->request;
            my $host    = ( $request )
                            ? $request->server_name
                            : CTX->server_config->{server_host};
            if ( $host ) {
                my $server_url = "http://$host" . DEPLOY_URL;
                $footer =~ s/\$LINK/$server_url$object_url/g;
            }
            else {
                $log->warn( "Cannot generate footer: no server host found. ",
                            "Please define server configuration key ",
                            "'Global.server_host' so I know what hostname to use." );
                return '';
            }
        }
        if ( $object_id ) {
            $footer =~ s/\$ID/$object_id/g;
        }
    }
    $log->is_info && $log->info( "Adding footer: $footer" );
    return $footer;
}

1;

__END__

=head1 NAME

OpenInteract2::Observer::UsePerlPost - Observer to post the contents of an object to a use.perl.org journal

=head1 SYNOPSIS

 # In your action.ini we need data to configure the journal post; this
 # can also be set programmatically if for instance you need to use
 # this for multiple users on your system
  
 [someaction]
 
 # ... normal action parameters ...
 
 # observer parameters
 # field with subject of post
 use_perl_subject  = title
 
 # field with content of post
 use_perl_content  = news_item
 
 # your use.perl userid
 use_perl_user_id  = 55
 
 # your password
 use_perl_password = foobar

 # In conf/observer.ini:
 
 # declare the observer
 [observer]
 useperl = OpenInteract2::Observer::UsePerlPost
 
 # hook it into the 'news' action so that 'post add' events fired will
 # add an entry into the journal
 
 [map]
 useperl = news

=head1 DESCRIPTION

This class is an L<OpenInteract2::Action> observer that takes the
object just added and fires off a posting to a C<use.perl.org> journal
with the contents. Thus keeping you in touch with your Perl peeps
while still using your favorite application server to hold all your
data.

What is an observer? See L<Class::Observer> for general information
and L<OpenInteract2::Observer> for specifics related to OpenInteract.

=head2 Configuration

B<use_perl_skip> (optional)

If this parameter set in the action or in the
L<OpenInteract2::Request> to 'yes' or 'true', this observer won't kick
off the journal addition. This allows you to stick a checkbox on the
form that adds your object to skip the use.perl part if you want. (For
instance, folks there might not dig your weekly cat photo post...)

B<use_perl_subject> (required)

Field/method to pull the subject of the use.perl post from.

B<use_perl_content> (required)

Field/method to pull the content of the use.perl post from.

B<use_perl_footer> (optional)

Text to use as the footer of the message posted. Any instance of
'$LINK' will be replaced by my best guess for the URL to display this
object, and '$ID' will be replaced by the object ID.

B<use_perl_user_id> (required)

ID of the user to use for authentication.

B<use_perl_password> (required)

Password for the given user ID.

B<use_perl_proxy> (optional)

Specify the 'Proxy' used in the L<Net::Blogger> call to create a
connection to the use.perl server. By default this is set to
'http://use.perl.org/journal.pl' and you should not need to change it.

B<use_perl_uri> (optional)

Specify the 'Uri' used in the L<Net::Blogger> call to create a
connection to the use.perl server. By default this is set to
'http://use.perl.org/Slash/Journal/SOAP' and should not need to change
it.

If you need to change either 'use_perl_proxy' or 'use_perl_uri' please
contact the author since it probably means the API has changed and the
default behavior of this module should be updated.

=head2 Modifying your content

We modify the content extracted from your object in the following
ways:

=over 4

=item *

All '<pre>' tags are replaced with '<ecode>' tags.

=item *

All '<img>' tags are removed and replaced with a link to the image and
text from that image's 'alt' attribute. If you don't specify an 'alt'
attribute we generate some lame text for you.

=back

=head1 SEE ALSO

L<Net::Blogger>

L<OpenInteract2::Observer>

L<OpenInteract2::Action>

L<Class::Observable>

=head1 COPYRIGHT

Copyright (c) 2004-5 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>

