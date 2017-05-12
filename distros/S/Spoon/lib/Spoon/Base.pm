package Spoon::Base;
use Spiffy 0.24 -Base;
use Spiffy qw(-yaml);
use Spiffy qw(WWW XXX YYY ZZZ);
# WWW - Creating a wrapper sub to require() IO::All caused spurious segfaults
use IO::All 0.32;
our @EXPORT = qw(io trace WWW XXX YYY ZZZ);
our @EXPORT_OK = qw(conf);

field used_classes => [];
field 'encoding';
const plugin_base_directory => './plugin';
field using_debug => 0;
field config_class => 'Spoon::Config';

sub hub {
    return $Spoon::Base::HUB 
      if defined($Spoon::Base::HUB) and not @_;
    Carp::confess "Too late to create a new hub. One already exists"
      if defined $Spoon::Base::HUB;
    
    my ($args, @config_files);
    {
        no warnings;
        local *paired_arguments = sub { qw(-config_class) };
        ($args, @config_files) = $self->parse_arguments(@_);
    }
    my $config_class = $args->{-config_class} || 
      $self->can('config_class')
      ? $self->config_class
      : 'Spoon::Config';
    eval "require $config_class"; die $@ if $@;
    my $config = $config_class->new(@config_files);
    my $hub_class = $config->hub_class;
    eval "require $hub_class";
    my $hub = $hub_class->new(
        config => $config,
        config_files => \@config_files,
    );
}

sub destroy_hub {
    undef $Spoon::Base::HUB;
}

sub init { }

sub assert {
    die "Assertion failed" unless shift;
}

sub trace() {
    require Spoon::Trace;
    no warnings;
    *trace = \ &Spoon::Trace::trace;
    goto &trace;
}

sub t {
    trace->mark;
    return $self;
}

sub conf() {
    my ($name, $default) = @_;
    my $package = caller;
    no strict 'refs';
    *{$package . '::' . $name} = sub {
        my $self = shift;
        return $self->{$name}
          if exists $self->{$name};
        $self->{$name} = exists($self->hub->config->{$name})
        ? $self->hub->config->{$name}
        : $default;
    };
}

sub clone {
    return bless {%$self}, ref $self;
}

sub is_in_cgi {
    defined $ENV{GATEWAY_INTERFACE};
}

sub is_in_test {
    defined $ENV{SPOON_TEST};
}

sub have_plugin {
    my $hub = $self->class_id eq 'hub'
    ? $self
    : $self->hub;
    local $@;
    eval { $hub->load_class(shift) }
}
    
sub plugin_directory {
    my $dir = join '/',
        $self->plugin_base_directory,
        $self->class_id,
    ;
    mkdir $dir unless -d $dir;
    return $dir;
}
    
sub debug {
    no warnings;
    if ($self->is_in_cgi) {
        eval 'use CGI::Carp qw(fatalsToBrowser)'; die $@ if $@;
        $SIG{__DIE__} = sub { CGI::Carp::confess(@_) }
    }
    else {
        require Carp;
        $SIG{__DIE__} = sub { Carp::confess(@_) }
    }
    $self->using_debug(1)
      if ref $self;
    return $self;
}

our ($UPPER, $LOWER, $ALPHA, $NUM, $ALPHANUM, $WORD, $WIKIWORD);
push @EXPORT_OK, qw($UPPER $LOWER $ALPHA $NUM $ALPHANUM $WORD $WIKIWORD);
our %EXPORT_TAGS = (char_classes => [@EXPORT_OK]);
if ($] < 5.008) {
    $UPPER    = 'A-Z\xc0-\xde';
    $LOWER    = 'a-z\xdf-\xff';
    $ALPHA    = $UPPER . $LOWER;
    $NUM      = '0-9';
    $ALPHANUM = $ALPHA . $NUM;
    $WORD     = $ALPHANUM . '_';
    $WIKIWORD = $WORD;
}
else {
    $UPPER    = '\p{UppercaseLetter}';
    $LOWER    = '\p{LowercaseLetter}';
    $ALPHA    = '\p{Letter}';
    $NUM      = '\p{Number}';
    $ALPHANUM = '\p{Letter}\p{Number}\pM';
    $WORD     = '\p{Letter}\p{Number}\p{ConnectorPunctuation}\pM';
    $WIKIWORD = "$UPPER$LOWER$NUM" . '\p{ConnectorPunctuation}\pM';
}

sub env_check {
    my $variable = shift;
    die "Environment variable '$variable' not set"
      unless defined $ENV{$variable};
}

sub dumper_to_file {
    my $path = shift;
    require Data::Dumper;
    no warnings;
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Terse = (@_ == 1) ? 1 : 0;
    local $Data::Dumper::Sortkeys = 1;
    io("$path")->assert->print(Data::Dumper::Dumper(@_));
}

# Codecs and Escaping
my $has_utf8;
sub has_utf8 {
    $has_utf8 = shift if @_;
    return $has_utf8 if defined($has_utf8);
    $has_utf8 = $] < 5.008 ? 0 : 1;
    require Encode if $has_utf8;
}

sub utf8_decode {
    $_[0] = Encode::decode('utf8', $_[0])
      if $self->has_utf8 and
         defined $_[0] and
         not Encode::is_utf8($_[0]);
    return $_[0];
}

sub utf8_encode {
    $_[0] = Encode::encode('utf8', $_[0])
      if $self->has_utf8 and
         defined $_[0];
    return $_[0];
}

sub uri_escape {
    require CGI::Util;
    my $data = shift;
    $self->utf8_encode($data);
    return CGI::Util::escape($data);
}

sub uri_unescape {
    require CGI::Util;
    my $data = shift;
    $data = CGI::Util::unescape($data);
    $self->utf8_decode($data);
    return $data;
}

# WWW - The CGI.pm version is broken in Chinese
sub html_escape {
    my $val = shift;
    $val =~ s/&/&#38;/g;
    $val =~ s/</&lt;/g; 
    $val =~ s/>/&gt;/g;
    $val =~ s/\(/&#40;/g;
    $val =~ s/\)/&#41;/g;
    $val =~ s/"/&#34;/g;
    $val =~ s/'/&#39;/g;
    return $val;
}

sub html_unescape { 
    CGI::unescapeHTML(shift);
}

sub base64_encode {
    require MIME::Base64;
    MIME::Base64::encode_base64(@_);
}

sub base64_decode {
    require MIME::Base64;
    MIME::Base64::decode_base64(@_);
}

# XXX Move to IO::All. Make more robust. Use Damian's prompting module.
package IO::All;

sub prompt {
    print shift;
    io('-')->chomp->getline;
}

__END__

=head1 NAME 

Spoon::Base - Generic Spoon Base Class

=head1 SYNOPSIS

    use Spoon::Base '-Base';

=head1 DESCRIPTION

Base class for application plugins.  Provides basic functionality to all
modules inheriting from this class.

=head1 SUBROUTINES

These subroutines are meant to be called bare, not as an object-method call.

=head2 trace

See Spoon::Trace::trace().

=head2 conf(name, default)

Returns the configuration value for "name", if it can be found in
the config ($self->hub->config).  Returns $default, otherwise.

=head1 METHODS

=head2 hub

Return the application's hub object.  See Spoon::Hub.

=head2 init

Inherited by all subclasses.  Put your class initialization stuff here.

=head2 assert(boolean)

Die if the supplied argument is false.

=head2 t([label])

Calls Spoon::Trace::mark().  See Spoon::Trace.

=head2 clone

Copies a class instance.  The copy is only a shallow one.

=head2 is_in_cgi

Returns a boolean, indicating whether we were called from a CGI interface.

=head2 is_in_test

Returns a boolean, indicating whether we were called from a test suite.

=head2 have_plugin(class_id)

Tries to load a plugin.  See Spoon::Hub::load_class().

=head2 plugin_directory

Returns your plugin's directory.  You can use this directory to store state.

=head2 env_check(variable_name)

Sanity check: ensure the specified variable exists in %ENV.  If the variable
is not found, dies with a useful error message.

=head2 dumper_to_file(filepath, variable1 [, variable2...])

Uses Data::Dumper to save a dump of one or more variables to the specified
file.

=head2 has_utf8

Returns a boolean, indicating whether utf8 is available on this platform and
version of perl.

=head2 utf8_encode(string)

Encodes the string in utf8, if utf8 is available.  Otherwise, returns $string
unmodified.  See Encode::encode().

=head2 utf8_decode(string)

Decodes the string from utf8, if utf8 is available.  Otherwise, returns $string
unmodified.  See Encode::decode().

=head2 uri_escape(string)

Escapes all invalid URI characters.  See CGI::Util::escape().

=head2 uri_unescape(string)

Unescapes all invalid URI characters.  See CGI::Util::unescape().

=head2 html_escape(string)

Escapes all reserved characters.  The result is suitable for including verbatim
in an HTML document.  See CGI::escapeHTML().

=head2 html_unescape(string)

Escapes all reserved characters.  The result is suitable for including verbatim
in an HTML document.  See CGI::unescapeHTML().

=head2 base64_encode(string)

Encodes the specified string into Base64.  See MIME::Base64::encode_base64().

=head2 base64_encode(base64_data)

Decodes the specified data from Base64.  See MIME::Base64::decode_base64().

=head1 TODO

* Document what Spoon::Base->debug() does. 

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
