package CGI::Kwiki;
$VERSION = '0.19';
@EXPORT = qw(attribute);
@CHAR_CLASSES = qw($ADMIN $UPPER $LOWER $ALPHANUM $WORD $WIKIWORD);
@EXPORT_OK = (@CHAR_CLASSES, qw(encode decode escape unescape));
%EXPORT_TAGS = (char_classes => [@CHAR_CLASSES]);

use strict;
use base 'Exporter';
use CGI qw(-no_debug);

use vars qw($ADMIN);
$ADMIN ||= 0;

use vars qw($UPPER $LOWER $ALPHANUM $WORD $WIKIWORD);
if ($] < 5.008) {
    $UPPER    = "A-Z\xc0-\xde";
    $LOWER    = "a-z\xdf-\xff";
    $ALPHANUM = "A-Za-z0-9\xc0-\xff";
    $WORD     = "A-Za-z0-9\xc0-\xff_";
    $WIKIWORD = $WORD;
}
else {
    $UPPER    = '\p{UppercaseLetter}';
    $LOWER    = '\p{LowercaseLetter}';
    $ALPHANUM = '\p{Letter}\p{Number}\pM';
    $WORD     = '\p{Letter}\p{Number}\p{ConnectorPunctuation}\pM';
    $WIKIWORD = "$UPPER$LOWER\\p{Number}\\p{ConnectorPunctuation}\\pM";
}

# All classes defined by CGI::Kwiki
sub classes {
    qw(
        new
        config
        config_yaml
        driver
        cgi
        cookie
        database
        metadata
        backup
        display
        edit
        formatter
        template
        plugin
        search
        changes
        prefs
        pages
        slides
        javascript
        style
        scripts
        blog
        i18n
        import
    )
}

# Traditional CGI runner
sub run_cgi {
    eval "use CGI::Carp qw(fatalsToBrowser)";
    die $@ if $@;

    my $cgi_class = (eval { require CGI::Fast; 1 } ? 'CGI::Fast' : 'CGI');
    while (my $cgi = $cgi_class->new) {
        my $driver = load_driver();
        $CGI::Kwiki::user_name = 
            $ENV{REMOTE_USER} || 
                CGI->remote_host();
        my $html = $driver->drive;
        if (ref $html) {
            print CGI::redirect($html->{redirect});
        } else {
            my $header = $driver->cookie->header;
            $driver->encode($header);
            $driver->encode($html);
            print $header, $html;
        }
        last if $cgi_class eq 'CGI';
    }
}

# Speedy mod_perl runner
sub handler {
    my ($r) = @_;
    my $base_directory = $_[1] || $r->location;
    chdir($base_directory) 
      or die "Can't chdir to '$base_directory'\n";
    eval "use Apache::Constants qw(OK REDIRECT)";
    die $@ if $@;

    my $driver = load_driver();
    $CGI::Kwiki::user_name = 
      $ENV{REMOTE_USER} ||
      $r->get_remote_host || 
      $r->connection->remote_ip;
    my $html = $driver->drive;
    if (ref $html) {
        $r->method('GET');
        $r->headers_in->unset('Content-length');
        $r->header_out('Location' => $html->{redirect});
        $r->status(&REDIRECT || 307);
        $r->send_http_header;
    }
    else {
        $r->print($driver->cookie->header, $html);
        $r->status(&OK || 200);
    }
    return;
}

# A generic class attribute set/get method generator
sub attribute {
    my ($attribute) = @_;
    my $pkg = caller;
    no strict 'refs';
    local $SIG{__WARN__} = sub {}; # shut up 'redefined' warnings
    *{"${pkg}::$attribute"} =
      sub {
          my $self = shift;
          return $self->{$attribute} unless @_;
          $self->{$attribute} = shift;
          return $self;
      };
}

# The most basic attributes inherited by almost all classes
attribute 'driver';
attribute 'config';
attribute 'cgi';
attribute 'plugin';
attribute 'template';
attribute 'formatter';
attribute 'database';
attribute 'metadata';
attribute 'backup';
attribute 'prefs';
attribute 'i18n';

# Constructor inherited by most classes
sub new {
    my ($class, $driver) = @_;
    my $self = bless {}, $class;
    $self->driver($driver);
    $self->config($driver->config);
    $self->cgi($driver->cgi);
    $self->plugin($driver->plugin);
    $self->template($driver->template);
    $self->formatter($driver->formatter);
    $self->database($driver->database);
    $self->metadata($driver->metadata);
    $self->backup($driver->backup);
    $self->prefs($driver->prefs);
    return $self;
}

sub load_driver {
    require CGI::Kwiki::Config;
    my $config = CGI::Kwiki::Config->new;
    my $driver_class = $config->driver_class;
    eval qq{ require $driver_class }; die $@ if $@;
    my $driver = $driver_class->new($config);
    $config->driver($driver);
    return $driver;
}

# I run a development Kwiki in the mykwiki/ subdirectory of CGI-Kwiki's
# development directory. I edit all the data files and templates in
# there, and then I use this rebuild method to pack them into the DATA
# sections of their respective modules.
sub rebuild {
    my $filename = $0;
    my $module = $filename;
    $module =~ s/.*lib\/(?=CGI)//;
    $module =~ s/\.pm$//;
    $module =~ s/\//::/g;
    my $self = $module->new(load_driver);
    my $data = '';
    my ($directory) = $self->directory;
    for my $file (sort glob("mykwiki/$directory/*")) {
        my $label = $file;
        $label =~ s/.*\///;
        $label =~ s/\.\w+$//;
        $data .= "__${label}__\n";
        open FILE, $file or die $!;
        $data .= do {local $/; <FILE>};
        close FILE;
    }
    $data =~ s/^=/^=/gm;
    open MODULE, $filename
      or die $!;
    my $module_text = do {local $/;<MODULE>};
    close MODULE;
    unless ($module_text =~ /^(.*__DATA__\n.*=cut\n\n)/s) {
        die "Can't parse $filename\n";
    }
    $module_text = $1 . $data;
    open MODULE, "> $filename"
      or die "Can't open $filename of output:\n$!";
    print MODULE $module_text;
    close MODULE;
    print "$filename updated\n";
    exit 0;
}

# Support for unpacking the DATA files attached to many CGI::Kwiki classes
sub create_files {
    my ($self) = @_;
    umask 0000;
    my $package = ref($self);
    my @files = split /^__([$WORD\/]+)__\n/m, $self->data;
    die $@ if $@;
    shift @files;
    my %files = @files;
    for my $file (keys %files) {
        my ($directory, $perms) = $self->directory($file);
        $perms ||= 0755;
        if (not -d $directory) {
            mkdir($directory, $perms);
        }
        $self->create_file(
            "$directory/" .  $self->name($file) . $self->suffix($file),
            $self->render_template($files{$file})
        );
    }
}

sub create_file {
    my ($self, $file_path, $content) = @_;
    open FILE, "> $file_path"
      or die "Can't open $file_path for output:\n$!";
    print FILE $content;
    close FILE;
    $self->perms($file_path);
}

sub directory { '.' }
sub suffix { '' }
sub name { $_[1] }
sub render_template { $_[1] }
sub perms {}
sub data {
    my ($self) = @_;
    my $package = ref($self);
    local $/;
    my $data = eval "package $package; <DATA>";
    die $@ if $@;
    return $data;
}

sub decode {
    my ($self) = @_;
    utf8::decode($_[1]) if $self->use_utf8 and defined $_[1];
    return $_[1] if defined wantarray;
}

sub encode {
    my ($self) = @_;
    utf8::encode($_[1]) if $self->use_utf8 and defined $_[1];
    return $_[1] if defined wantarray;
}

sub escape {
    my ($self, $data) = @_;
    $self->encode($data);
    return CGI::Util::escape($data);
}

sub unescape {
    my ($self, $data) = @_;
    $data = CGI::Util::unescape($data);
    $self->decode($data);
    return $data;
}

my $use_utf8;
sub use_utf8 {
    my ($self) = @_;
    $use_utf8 = $_[1] if @_ > 1;
    return $use_utf8 if defined($use_utf8);
    return($use_utf8 = 0) if $] < 5.008;
    return 1 unless $self->config;
    return($use_utf8 = (lc($self->config->encoding) =~ /^utf-?8$/));
}

sub loc {
    my ($self) = shift;
    my $i18n_class = $self->config->{i18n_class} or die;
    eval "use $i18n_class; 1" or return $_[0];
    $i18n_class->initialize($self->use_utf8 || 0);
    return $i18n_class->loc(@_);
}

1;

__END__

=head1 NAME

CGI::Kwiki - A Quickie Wiki that's not too Tricky

=head1 SYNOPSIS

    > mkdir cgi-bin/my-kwiki
    > cd cgi-bin/my-kwiki
    > kwiki-install

    Kwiki software installed! Point your browser at this location.

=head1 KWIK START

The Offficial Kwiki Home is at http://www.kwiki.org. This site is a
Kwiki itself. It contains much more information about Kwiki than the
distributed docs.

=head1 DESCRIPTION

A Wiki is a website that allows its users to add pages, and edit any
existing pages. It is one of the most popular forms of web
collaboration. If you are new to wiki, visit
http://c2.com/cgi/wiki?WelcomeVisitors which is possibly the oldest
wiki, and has lots of information about how wikis work.

There are dozens of wiki implementations in the world, and many of those
are written in Perl. As is common with many Perl hacks, they are rarely
modular, and almost never released on CPAN. One major exception is
CGI::Wiki. This is a wiki framework that is extensible and is actively
maintained.

Another exception is this module, CGI::Kwiki. CGI::Kwiki focuses on
simplicity and extensibility. You can create a new kwiki website with a
single command. The module has no prerequisite modules, except the
ones that ship with Perl. It doesn't require a database backend,
although it could be made to use one. The default kwiki behaviour is
fairly full featured, and includes support for html tables. Any
behaviour of the kwiki can be customized, without much trouble.

=head1 SPECIAL FEATURES

CGI::Kwiki will come with some fancy addons not found in most wiki
implementations. This comes with the promise that they will not
interfere with the sheer simplicity of the default kwiki interface.

Check http://http://www.kwiki.org/index.cgi?KwikiFeatures from time to
time to see what hot features have been added.

=head2 Kwiki Slide Show

You can create an entire PowerPoint-like slideshow, in a single kwiki
page. There is Javascript magic for advancing slides, etc. See the
sample page KwikiSlideShow.

=head1 EXTENDING

CGI::Kwiki is completely Object Oriented. You can easily override every
last behaviour by subclassing one of its class modules and overriding
one or more methods. This is generally accomplished in just a few
lines of Perl.

The best way to describe this is with an example. Start with the config
file. The default config file is called C<config.yaml>. It contains a
set of lines like this:

    config_class:      CGI::Kwiki::Config
    driver_class:      CGI::Kwiki::Driver
    cgi_class:         CGI::Kwiki::CGI
    cookie_class:      CGI::Kwiki::Cookie
    database_class:    CGI::Kwiki::Database
    metadata_class:    CGI::Kwiki::Metadata
    display_class:     CGI::Kwiki::Display
    edit_class:        CGI::Kwiki::Edit
    formatter_class:   CGI::Kwiki::Formatter
    template_class:    CGI::Kwiki::Template
    search_class:      CGI::Kwiki::Search
    changes_class:     CGI::Kwiki::Changes
    prefs_class:       CGI::Kwiki::Prefs
    pages_class:       CGI::Kwiki::Pages
    slides_class:      CGI::Kwiki::Slides
    javascript_class:  CGI::Kwiki::Javascript
    style_class:       CGI::Kwiki::Style
    scripts_class:     CGI::Kwiki::Scripts

This is a list of all the classes that make up the kwiki. You can change
anyone of them to be a class of your own.

Let's say that you wanted to change the B<BOLD> format indicator from
C<*bold*> to C<'''bold'''>. You just need to override the C<bold()>
method of the Formatter class. Start by changing C<config.yaml>.

    formatter_class: MyKwikiFormatter

Then write a module called C<MyKwikiFormatter.pm>. You can put this
module right in your kwiki installation directory if you want. The
module might look like this:

    package MyKwikiFormatter;
    use base 'CGI::Kwiki::Formatter';

    sub bold {
        my ($self, $text) = @_;
        $text =~ s!'''(.*?)'''!<b>$1</b>!g;
        return $text;
    }

    1;

Not too hard, eh? You can change all aspects of CGI::Kwiki like this,
from the database storage to the search engine, to the main driver code.
If you come up with a set of classes that you want to share with the
world, just package them up as a distribution and put them on CPAN.

By the way, you can even change the configuration file format from the
YAML default. If you wanted to use say, XML, just call the file
C<config.xml> and write a module called C<CGI::Kwiki::Config_xml>.

=head1 SEE ALSO

All of the rest of the documentation for CGI::Kwiki is available within
your own Kwiki installation. Just install a Kwiki and follow the links!
If you're having trouble or just want to see a Kwiki in action, visit
http://www.kwiki.org first.

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
