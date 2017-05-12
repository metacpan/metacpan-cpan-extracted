package POE::Component::IRC::Plugin::FTP::EasyUpload;

use warnings;
use strict;

our $VERSION = '0.002';

use Carp;
use POE qw(Component::Net::FTP);
use Devel::TakeHashArgs;
use POE::Component::IRC::Plugin qw( :ALL );

sub new {
    my $class = shift;
    get_args_as_hash( \@_, \ my %args, {
            port            => 21,
            timeout         => 30,
            pub_uri         => '',
            retries         => 5,
            verbose_error   => 1,
            tag             => qr/<irc_ftp:(.+?):(.*?):(.*?)>/,
        },
        [ qw(host login pass) ],
        [
            qw( host  login  pass  obj_args  timeout  pub_uri  debug
                retries  tag  port  verbose_error unique
            )
        ],
    ) or croak $@;


    $args{pub_uri} = $args{host}
        unless defined $args{pub_uri};

    my $self = bless \%args, $class;

    return $self;
}

sub PCI_register {
    my ($self, $irc) = @_;

    $self->{irc} = $irc;

    $irc->plugin_register( $self, 'USER', qw(privmsg notice) );

    $self->{session_id} = POE::Session->create(
        object_states => [
            $self => [qw(_start  _processed  _shutdown)],
        ],
    )->ID();

    return 1;
}

sub U_privmsg { my $self = shift; $self->_process( @_ ); }
sub U_notice  { my $self = shift; $self->_process( @_ ); }

sub _process {
    my ( $self, $irc, $out_ref ) = @_;
    $self->{debug}
        and carp "OUT: $$out_ref";

        
    if ( my ( $file, $dir, $prefix ) = $$out_ref =~ /$self->{tag}/ ) {
        $prefix = ''
            unless defined $prefix;

        $self->{debug}
            and carp "[ file => $file, dir => $dir, prefix => $prefix ]";

        $self->{poco}->process( {
                event       => '_processed',
                session     => $self->{session_id},
                _out        => $$out_ref,
                _try        => 0,
                _prefix     => $prefix,
                commands    => [
                   { new => [
                            $self->{host},
                            Timeout => $self->{timeout},
                            Port    => $self->{port},
                            @{ $self->{obj_args} || [] },
                        ],
                   },
                   { login  => [ $self->{login}, $self->{pass} ] },

                   defined $dir ? ( { cwd => [ $dir ] } ) : (),

                   $self->{unique} ? { put_unique => [ $file ] }
                                   : { put => [ $file ] },
                ],
            },
        );

        return PCI_EAT_ALL;
    }
    return PCI_EAT_NONE;
}

sub _processed {
    my ( $kernel, $self, $in_ref ) = @_[ KERNEL, OBJECT, ARG0 ];
    my $out_message;
    if ( $in_ref->{is_error} ) {
        $self->{debug}
            and carp "FTP error on $in_ref->{error} command: "
                        . $in_ref->{last_error};

        if ( $self->{retries} < $in_ref->{_try}++ ) {
            $self->{debug}
                and carp "Retring after error [retry # $in_ref->{_try}]";

            delete @$in_ref{ qw(error responses) };
            $self->{poco}->process( $in_ref );
            return;
        }
        $in_ref->{last_error} =~ s/\n|\r//g;
        $out_message = $self->{verbose_error}
                        ? "[FTP Error: $in_ref->{last_error}]"
                        : '[FTP Error]';
    }
    else {
        $out_message = $self->{pub_uri}
                            . $in_ref->{_prefix}
                            . $in_ref->{responses}[-1][0];
    }
    $in_ref->{_out} =~ s/$self->{tag}/$out_message/g;
    $kernel->post( $self->{irc} => quote => $in_ref->{_out} );
    return;
}

sub PCI_unregister {
    my ($self, $irc) = @_;
    $poe_kernel->call( $self->{session_id} => '_shutdown' );
    delete $self->{irc};

    return 1;
}

sub _start {
    my ( $kernel, $self ) = @_[KERNEL, OBJECT];
    $self->{session_id} = $_[SESSION]->ID();
    $kernel->refcount_increment( $self->{session_id}, __PACKAGE__ );

    $self->{poco} = POE::Component::Net::FTP->spawn(
        $self->{debug} ? ( debug => $self->{debug} ) : ()
    );

    return;
}

sub _shutdown {
    my ( $kernel, $self ) = @_[KERNEL, OBJECT];
    $self->{poco}->shutdown;
    $kernel->alarm_remove_all();
    $kernel->refcount_decrement( $self->{session_id}, __PACKAGE__ );

    return;
}

1;
__END__

=encoding utf8

=head1 NAME

POE::Component::IRC::Plugin::FTP::EasyUpload - provide files to IRC users via FTP

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC  Component::IRC::Plugin::FTP::EasyUpload);

    die "Usage: perl ftp_bot.pl <host> <login> <password>\n"
        unless @ARGV == 3;

    my ( $Host, $Login, $Password ) = @ARGV;

    my $irc = POE::Component::IRC->spawn(
        nick        => 'FTPBot',
        server      => 'irc.freenode.net',
        port        => 6667,
        ircname     => 'FTP uploading bot',
    );

    POE::Session->create(
        package_states => [
            main => [ qw(_start irc_001  irc_public) ],
        ],
    );

    $poe_kernel->run;

    sub _start {
        $irc->yield( register => 'all' );

        $irc->plugin_add(
            'FTPEasyUpload' =>
                POE::Component::IRC::Plugin::FTP::EasyUpload->new(
                    host    => $Host,
                    login   => $Login,
                    pass    => $Password,
                    pub_uri => 'http://zoffix.com/',
                )
        );

        $irc->yield( connect => {} );
    }

    sub irc_001 {
        $irc->yield( join => '#zofbot' );
    }

    sub irc_public {
        $irc->yield( privmsg => '#zofbot' => 'See <irc_ftp:test.txt:public_html:>' );
    }

    <Zoffix> blargh
    <FTPBot> See http://zoffix.com/test.txt

=head1 DESCRIPTION

Being a bot herder as I am I often needed to upload some file there
somewhere and post a link to IRC so other users could grab the file...
So here it is, FTP uploading plugin which watches for special "tags" in
the outgoing messages which tell it to upload certain file.

B<Note:> uploading is done in a B<non-blocking> way, keep that in mind
in case you'd want to send some messages in a certain sequence.

=head1 HOW DOES IT WORK

Process is simple. Your "tag" is a regex with one to three capturing
parentheses (see C<tag> argument to constructor). Based on those captures
the specified file will be uploaded to a specified directory and the
"tag" will be replaced by the URI pointing to that file. After all that
message will be sent where it was supposed to go.

The plugin watches for "tags" in C<privmsg> and C<notice> message.

=head1 CONSTRUCTOR

=head2 C<new>

    # plain
    $irc->plugin_add(
        'FTPEasyUpload' =>
            POE::Component::IRC::Plugin::FTP::EasyUpload->new(
                host    => 'ftp.some-host.com',
                login   => 'zoffer',
                pass    => 'some-password',
            )
    );

    # juicy
    $irc->plugin_add(
        'FTPEasyUpload' =>
            POE::Component::IRC::Plugin::FTP::EasyUpload->new(
                host            => $Host,
                login           => $Login,
                pass            => $Password,
                pub_uri         => 'http://zoffix.com/',
                unique          => 1,
                port            => 21,
                timeout         => 30,
                retries         => 3,
                verbose_error   => 1,
                tag             => qr/<irc_ftp:(.+?):(.*?):(.*?)>/,
                obj_args        => [ Passive => 1, Debug => 1 ],
                debug           => 1,
        },
    );

Creates a new POE::Component::IRC::Plugin::FTP::EasyUpload object
suitable to be fed to C<plugin_add()> method of L<POE::Component::IRC>
object. Takes quite a few arguments but most of them are optional.
Arguments are passed as key/value pairs. B<Note:> most of these arguments
can be changed dynamically by accessing them as keys in your plugin object.
In other words, to change the C<retries> argument you'd do it as
C<< $your_plugin_object->{retries} = 10; >>. Possible arguments are as
follows:

=head3 C<host>

    ->new( host => 'ftp.some.host.com' );

B<Mandatory>. Takes a scalar as a value which must be the host of the
FTP server to which you want to upload your files.

=head3 C<login>

    ->new( login => $Login );

B<Mandatory>. Takes a scalar as a value which must be the login (user name)
with which to login into your FTP account.

=head3 C<pass>

    ->new( pass => $Password );

B<Mandatory>. Takes a scalar as a value which must be the password to use
to login into your FTP account.

=head3 C<port>

    ->new( port => 21, );

B<Optional>. Takes a scalar as a value which specifies the port number
of FTP server to which we shall connect. B<Defaults to:> C<21>

=head3 C<timeout>

    ->new( timeout => 30, );

B<Optional>. Takes a scalar as a value which specifies the timeout in
seconds for FTP operations. B<Defaults to:> C<30>

=head3 C<retries>

    ->new( retries => 5, );

B<Optional>. The plugin is capable of retrying the upload if the previous
attempt failed. Takes a scalar as a value which specifies the number of
times to retry the upload. If after trying C<retries> times upload still
errored out the "tag" will be replaced with either C<[FTP Error]> or
the error message (see C<verbose_error> argument below).
B<Defaults to:> C<5>

=head3 C<obj_args>

    ->new( obj_args => [ Passive => 1, Debug => 1 ] );

B<Optional>. Takes an I<arrayref> as a value. If specifies it will be
directly dereferenced into the constructor of L<Net::FTP> object. See
documentation for L<Net::FTP> for possible arguments. B<By default> not
specified.

=head3 C<verbose_error>

    ->new( verbose_error => 1 );

B<Optional>. If upload fails (see C<retries> argument above) the "tag"
(see below) will be replaced by an error message. The C<verbose_error>
argument specifies whether the error should be a generic one or should
it describe the problem. Takes either true or false value. When set to a
true value the "tag" will be replaced by C<[FTP Error: error_message]>
where C<error_message> will be the text describing why the error occured.
When C<verbose_error> argument is set to a false value the "tag" will
be replaced by a generic message indicating that an error occured which
looks like C<[FTP Error]>. B<Defaults to:> C<1>

=head3 C<tag>

    ->new( tag => qr/<irc_ftp:(.+?):(.*?):(.*?)>/, );

B<Optional>. Here is where you can specify for what plugin should look
for when deciding what to upload. The C<tag> argument takes a regex
(C<qr//>) as a value. The regex must contain at least one capturing group
of parentheses but normally you'd want to have three there. The capturing
parentheses capture the filename of the file to upload, directory to C<cd>
into (on the server) before uploading and the text to prepend to
C<pub_uri> (see below) before sending the message to IRC. In other words,
if your C<tag> argument is set to C<< qr/<irc_ftp:(.+?):(.*?):(.*?)>/ >>,
your C<pub_uri> argument (see below) is set to C<http://foo.com/>
and you send an IRC message
C<< "See <irc_ftp:test.txt:public_html:stuff/>" >> then the plugin will
connect to your FTP server, change into C<public_html> directory, upload
file C<test.txt> and if everything went well will send message
C<< "See http://foo.com/stuff/test.txt" >> to IRC (providing
C<unique> argument (see below) is set to a false value).

B<Defaults to:> C<< qr/<irc_ftp:(.+?):(.*?):(.*?)>/ >>

=head3 C<pub_uri>

    ->new( pub_uri  => 'http://zoffix.com/', );

B<Optional>. Takes a scalar as a value which will be prepended to
the filename of the uploaded file. In other words, if you uploaded file
named C<test.txt> and your C<pub_uri> argument is set to C<http://test.com/>
then the "tag" (see above) will be replaced with text
C<http://test.com/test.txt>. B<Defaults to:> empty string

=head3 C<unique>

    ->new( unique => 1, );

B<Optional>. Takes either a true or false value. When set to a true value
will use C<put_unique> to upload a file meaning the uploaded filename
should be uniquely generated by the server. When set to a false value the
uploaded file will have the same name as the original (the local one).
B<Defaults to:> C<0>

=head3 C<debug>

    ->new( debug => 1, );

B<Optional>. Takes either a true or false value. When set to a true value
the plugin will C<carp()> out some debuging info. B<Note:> this does
not affect the C<Debug> argument of L<Net::FTP> object. B<Defaults to:> C<0>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-irc-plugin-ftp-easyupload at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-IRC-Plugin-FTP-EasyUpload>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::IRC::Plugin::FTP::EasyUpload

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-IRC-Plugin-FTP-EasyUpload>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-IRC-Plugin-FTP-EasyUpload>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-IRC-Plugin-FTP-EasyUpload>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-IRC-Plugin-FTP-EasyUpload>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

