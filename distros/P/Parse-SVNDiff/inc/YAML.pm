#line 1 "inc/YAML.pm - /usr/local/lib/perl5/site_perl/5.8.7/YAML.pm"
package YAML;
use YAML::Base -base;
require 5.6.1;
our $VERSION = '0.49_50';
our @EXPORT = qw'Dump Load';
our @EXPORT_OK = qw'freeze thaw DumpFile LoadFile Bless Blessed';

# This line is here to convince "autouse" into believing we are autousable.
sub can {
    ($_[1] eq 'import' and caller()->isa('autouse'))
        ? \&Exporter::import        # pacify autouse's equality test
        : $_[0]->SUPER::can($_[1])  # normal case
}

# XXX This value nonsense needs to go.
use constant VALUE => "\x07YAML\x07VALUE\x07";

# Global Options are an idea taken from Data::Dumper. Really they are just
# sugar on top of real OO properties. They make the simple Dump/Load API
# easy to configure.

# New global options
our $SpecVersion = '1.0';
our $LoaderClass = '';
our $DumperClass = '';

# Legacy global options
our $Indent         = 2;
our $UseHeader      = 1;
our $UseVersion     = 0;
our $SortKeys       = 1;
our $AnchorPrefix   = '';
our $UseCode        = 0;
our $DumpCode       = '';
our $LoadCode       = '';
our $UseBlock       = 0;
our $UseFold        = 0;
our $CompressSeries = 1;
our $UseAliases     = 1;

# YAML Object Properties
field dumper_class => 'YAML::Dumper';
field loader_class => 'YAML::Loader';
field dumper_object =>
    -init => '$self->init_action_object("dumper")';
field loader_object =>
    -init => '$self->init_action_object("loader")';

sub Dump {
    my $yaml = 'YAML'->new;
    $yaml->dumper_class($DumperClass)
        if $DumperClass;
    return $yaml->dumper_object->dump(@_);
}

sub Load {
    my $yaml = YAML->new;
    $yaml->loader_class($LoaderClass)
        if $LoaderClass;
    return $yaml->loader_object->load(@_);
}

sub DumpFile {
    my $filename = shift;
    local $/ = "\n"; # reset special to "sane"
    my $mode = '>';
    if ($filename =~ /^\s*(>{1,2})\s*(.*)$/) {
        ($mode, $filename) = ($1, $2);
    }
    open my $OUT, $mode, $filename
      or $self->die("Can't open '$filename' for output:\n$!");
    print $OUT Dump(@_);
}

{
    no warnings 'once';
    # freeze/thaw is the API for Storable string serialization. Some
    # modules make use of serializing packages on if they use freeze/thaw.
    *freeze = \ &Dump;
    *thaw   = \ &Load;
    # This 
}

sub LoadFile {
    my $filename = shift;
    open my $IN, $filename
      or $self->die("Can't open '$filename' for input:\n$!");
    return Load(do { local $/; <$IN> });
}   

sub init_action_object {
    my $self = shift;
    my $object_class = (shift) . '_class';
    my $module_name = $self->$object_class;
    eval "require $module_name";
    die "Error in require $module_name - $@"
        if $@ and "$@" !~ /Can't locate/;
    my $object = $self->$object_class->new;
    $object->set_global_options;
    return $object;
}

my $global = {};
sub Bless {
    require YAML::Dumper::Base;
    YAML::Dumper::Base::bless($global, @_)
}
sub Blessed {
    require YAML::Dumper::Base;
    YAML::Dumper::Base::blessed($global, @_)
}
sub global_blessings { $global }

__END__

#line 783
