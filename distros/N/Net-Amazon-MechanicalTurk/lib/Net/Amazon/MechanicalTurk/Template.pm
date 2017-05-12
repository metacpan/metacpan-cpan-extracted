package Net::Amazon::MechanicalTurk::Template;
use warnings;
use strict;
use Carp;
use Net::Amazon::MechanicalTurk::BaseObject;
use Net::Amazon::MechanicalTurk::ModuleUtil;
use Net::Amazon::MechanicalTurk::IOUtil;
use IO::File;
use IO::Dir;

our $VERSION = '1.00';

our @ISA = qw{ Net::Amazon::MechanicalTurk::BaseObject };
our %EXTENSION_MAPPINGS;
our $DEFAULT_EXTENSIONS_LOADED = 0;

our %DEFAULT_EXTENSIONS = (
    "Net::Amazon::MechanicalTurk::Template::ReplacementTemplate" => ['rt', 'question'],
    "Net::Amazon::MechanicalTurk::Template::PerlTemplate" => ['pl']
);

Net::Amazon::MechanicalTurk::Template->attributes(qw{
    templateFile
    templateSource
    compiled
});


# Class methods

sub toTemplate {
    my $class = shift;
    my $source = shift;
    if (UNIVERSAL::isa($source, "Net::Amazon::MechanicalTurk::Template")) {
        return $source;
    }
    elsif (UNIVERSAL::isa($source, "CODE")) {
        require Net::Amazon::MechanicalTurk::Template::SubroutineTemplate;
        return Net::Amazon::MechanicalTurk::Template::SubroutineTemplate->new(
            sub => $source
        );
    }
    else {
        return $class->compile($source);
    }
}

sub compile {
    my $class = shift;
    my $file = shift;
    my $module = $class->getModuleForFile($file);
    if (!defined($module)) {
        Carp::croak("Can't find module to handle file $file.");
    }
    return $module->new(templateFile => $file, @_);
}

sub getModuleForFile {
    my ($class, $file) = @_;
    my $ext = $file;
    $ext =~ s/^.*\.//;
    $ext = lc($ext);
    if (!$DEFAULT_EXTENSIONS_LOADED) {
        Net::Amazon::MechanicalTurk::Template->addExtensionMappings(%DEFAULT_EXTENSIONS);
        $DEFAULT_EXTENSIONS_LOADED = 1;
    }
    return $EXTENSION_MAPPINGS{$ext};
}

sub addExtensionMappings {
    my $class = shift;
    my %params = ($#_ == 0 and UNIVERSAL::isa($_[0], "HASH")) ? %{$_[0]} : @_;
    my $result = 1;
    while (my ($module, $extensions) = each %params) {
        if (!UNIVERSAL::can($module, "new")) {
            if (Net::Amazon::MechanicalTurk::ModuleUtil->tryRequire($module)) {
                if (!UNIVERSAL::can($module, "new")) {
                    $result = 0;
                    Carp::carp("Couldn't find constructor in module $module - $@");
                    next;
                }
            }
            else {
                $result = 0;
                Carp::carp("Couldn't load module $module - $@.");
                next;
            }
        }
        foreach my $extension (@$extensions) {
            $EXTENSION_MAPPINGS{lc($extension)} = $module;
        }
    }
    return $result;
}

# Instance methods

sub init {
    my $self = shift;
    $self->setAttributes(@_);
    if (defined($self->templateFile)) {
        $self->compileFile($self->templateFile);
    }
    elsif (defined $self->templateSource) {
        $self->templateFile("<memory>");
        $self->compileSource($self->templateSource);
    }
    if (!$self->compiled) {
        Crap::croak("Couldn't compile template.");
    }
}

sub compileFile {
    my ($self, $file) = @_;
    my $text = Net::Amazon::MechanicalTurk::IOUtil->readContents($file);
    $self->templateFile($file);
    $self->compileSource($text);
}

sub compileSource {
    my ($self, $source) = @_;
    # Subclass should implement
}

sub execute {
    my $self = shift;
    my %params = ($#_ == 0 and UNIVERSAL::isa($_[0], "HASH")) ? %{$_[0]} : @_;
    return $self->merge(\%params);
}

sub merge {
    my ($self, $params) = @_;
    # Subclass should implement this
}

return 1;
