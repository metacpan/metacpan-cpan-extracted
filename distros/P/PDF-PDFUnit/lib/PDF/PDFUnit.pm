#####################
package PDF::PDFUnit;
#####################
use strict;
use warnings;
use feature ':5.10';
use File::Basename;
use File::Find;
use Data::Dumper;
use English;
use Carp;

BEGIN {
    @PDF::PDFUnit::EXPORT = qw( DEBUG );
}

# These two extend the @EXPORT list:
use PDF::PDFUnit::Shortcuts;
use PDF::PDFUnit::Constants;

use PDF::PDFUnit::StudyClasses;

require Exporter;
our @ISA = qw(Exporter);


$PDF::PDFUnit::VERSION = 0.17;

$PDF::PDFUnit::PDFUNIT_JAVA_VERSION = "2016.05";




our $instance = {
    is_loaded   => 0,
    is_sane     => 0,
    config_path => undef,
    classpath_elements => [],
};


sub val {
    my ($class, $key);

    
    if ($_[0] eq  __PACKAGE__) {
        ($class, $key) = @_;
    }
    else {
        ($key) = @_;
    }

    return $instance->{$key};
}


###########
sub DEBUG {
###########
    my $debug_level = $ENV{PDFUNIT_PERL_DEBUG} // 0;

    my ($msg, $level) = @_;
    $level //= 1;
    return unless  $debug_level >= $level; 

    my $prefix = "***[${level}] ";

    my @msg = split(/\n/, $msg);
    
    say STDERR $prefix, $_ foreach @msg;
}


sub import {
    my ($package, $init_style) = @_;

    if (defined $init_style) {

        unless (grep {$init_style eq $_} qw(:skip_on_error :noinit)) {
            carp "Unknown import tag: '$init_style'";
        }
    }

    if (defined $init_style && $init_style eq ':skip_on_error') {
        $package->init(skip_on_error => 1);
    }
    
    unless (defined $init_style && $init_style eq ':noinit') {
        $package->init();
    }

    @_ = ($package);

    goto &Exporter::import;
}


##########
sub init {
##########
    my $class = shift;

    $class->load_config(@_)      &&
    $class->build_classpath(@_)  &&
    $class->attach_java(@_);
}
    



#################
sub load_config {
#################
    my $class = shift;
    my %args = @_;

    return 1 if $instance->{is_loaded};
        
    DEBUG "Operating system: $OSNAME";

    my $config_found;
    
    foreach (@{os_dep()->{cfg_locations}}) {

        my $location_as_text = $_;
        my $location         = $_;

        
        if ( my ($envar) = m/ENV%(.*?)%/ ) { # Environment var

            my $env_prefix = $class->os_dep()->{env_prefix};
            my $env_suffix = $class->os_dep()->{env_suffix};
            
            $location_as_text =~ s/ENV%(.*?)%/$env_prefix$envar$env_suffix/;

            if (exists $ENV{$envar}) {
                $location =~ s/ENV%(.*?)%/$ENV{$envar}/;
            }
            else {
                $location = undef;
            }
        }

        DEBUG "Possible config location: $location_as_text", 2;

        if (defined $location && -r $location) {
            $config_found = $location;
            DEBUG "Found readable config: $location";
            last;
        }
    }

    unless ($config_found) {
        my $msg = "No configuration found";
        
        if ($args{skip_on_error}) {
            _skip_all_tests($msg);
        }
        
        warn "$msg\n";
        return 0;
    }

    $instance->{config_path} = $config_found;

    open(my $cfghandle, "<", $config_found)
        || die "$config_found: $!\n";
    DEBUG "Config opened for reading", 2;


    # Valid configuration options:
    my %config_schema = (
        pdfunit_java_home => 'mandatory',
        pdfunit_root      => 'deprecated;pdfunit_java_home',
        outfox_display    => 'optional',
    );

    my %config = (); # This will be filled

    while (<$cfghandle>) {
        chomp;
        next if /^#/;
        next if /^\s*$/;

        my ($key, $value) = split(/\s*=\s*/, $_, 2);
        
        if (!exists $config_schema{$key}) {
            warn("$config_found: Invalid key: $key\n");
        }
        else {
            DEBUG "Found key/value: $key = $value";
            
            if ($config_schema{$key} =~ /^deprecated;/) {
                my ($new_name) = (split(/;/, $config_schema{$key}))[1];
                warn "Deprecated configuration key: $key "
                    . "(use $new_name instead)\n";
                $config{$new_name} = $value;
            }
            else {
                $config{$key} = $value;
            }
        }

    }
    close $cfghandle;
    
    # Do we have values for all mandatory config keys?
    foreach (grep { $config_schema{$_} eq 'mandatory'}  keys %config_schema) {
        unless (exists $config{$_}) {
            my $msg = "Missing mandatory key in configuration: $_";
        
            if ($args{skip_on_error}) {
                _skip_all_tests($msg);
            }
        
            die "$msg\n";
        }
    }

    # Now put all found keys into the instance:
    foreach (keys %config) {
        $instance->{$_} = $config{$_};
    }

    

    $instance->{is_loaded} = 1;

    return 1;
}




#####################
sub build_classpath {
#####################
    my $class = shift;
    my %args = @_;
    
    return 1 if $instance->{is_sane};

    DEBUG "Building CLASSPATH.";

    my $pdfunit_java_home = glob($class->val('pdfunit_java_home'));

    DEBUG "Searching for jar files under $pdfunit_java_home";

    unless (-d $pdfunit_java_home) {
        my $msg = "Configured pdfunit_java_home is not a directory";
        
        if ($args{skip_on_error}) {
            _skip_all_tests($msg);
        }

        die "$msg\n";
    }
    
    find(\&_wanted, $pdfunit_java_home);

    # The root directory of PDFUnit has to be in the classpath
    # (otherwise the license file cannot be read):
    unshift @{$instance->{classpath_elements}}, $pdfunit_java_home;

    my $count = @{$instance->{classpath_elements}};
    DEBUG "Detected $count elements for classpath.";

    $ENV{CLASSPATH} = join(os_dep()->{env_pathlist_sep_char},
                           @{$instance->{classpath_elements}});

    
    # (Weak) consisteny check of classpath elements:
    
    my @contains_main_jar =
        grep { /^pdfunit-java-.*\.jar$/ }
        map { basename $_ } @{$instance->{classpath_elements}};

    
    if ( @contains_main_jar && $count >= 20) {
        DEBUG "Setup seems to be sane!";
        
        $instance->{is_sane} = 1;

        return 1;
    }
    else {
        my $msg = "Cannot build a sane CLASSPATH - no suitable jars found in "
            . $pdfunit_java_home;
        
        if ($args{skip_on_error}) {
            _skip_all_tests($msg);
        }

        die "$msg\n";
    }
}


sub _wanted {
    return unless /\.jar$/i;

    DEBUG "Found jar: $_", 2;
    push @{$instance->{classpath_elements}}, $File::Find::name;
}


#################
sub attach_java {
#################
    my $class = shift;
    my %args = @_;

    return 0 unless $instance->{is_sane};

        
    $ENV{DISPLAY} = $class->val('outfox_display')
        if defined $class->val('outfox_display'); 


    DEBUG("Attaching Java with Inline::Java");
    
    eval {
        require Inline;
        import Inline (
            Java      => 'STUDY',
            STUDY     => $PDF::PDFUnit::StudyClasses::java_classes,
            PACKAGE   => 'main',
            AUTOSTUDY => 1,
        );
    };

    if ($@) {
        if ($args{skip_on_error}) {
            _skip_all_tests($@);
        }

        warn $@;
        return 0;
    }

    return 1;
}


sub _skip_all_tests {
    my ($msg) = @_;
    
    require Test::More;
    import Test::More (
        skip_all => ($msg)
    );

    exit 1;
}



############
sub os_dep {
############
    my $class = shift;

    my $cfgname = 'pdfunit-perl.cfg';

    my $os_dep = {
        linux => {
            env_pathlist_sep_char => ':',

            env_prefix => '$',
            env_suffix => '',
            
            cfg_locations => [
                "ENV%PDFUNIT_PERL_CONFIG%",
                "./$cfgname",
                "ENV%HOME%/.$cfgname",
                "/etc/$cfgname"
            ],
        },
        
        MSWin32 => {
            env_pathlist_sep_char => ';',
            
            env_prefix => '%',
            env_suffix => '%',

            cfg_locations => [
                "ENV%PDFUNIT_PERL_CONFIG%",
                ".\\$cfgname",
                "ENV%HOMEPATH%\\.$cfgname",
                "ENV%USERPROFILE%\\.$cfgname",
                "ENV%LOCALAPPDATA%\\pdfunit-perl\\$cfgname",
            ],
        },
    };

    return $os_dep->{$OSNAME};
}







1;


__END__

=head1 NAME

PDF::PDFUnit - Perl interface to the Java PDFUnit testing framework

=head1 IMPORTANT

I<This Module is not useable on its own>!

It it "just" a Perl wrapper
around Carsten Siedentop's awesome L<B<PDFUnit>|http://pdfunit.com/>
(a PDF testing framework written in Java).

=head1 SYNOPSIS

  use PDF::PDFUnit;

  AssertThat
      ->document("test.pdf")
      ->hasNumberOfPages(1)
       ;

...or (more typical):

  use Test::More;
  use Test::Exception;
  use PDF::PDFUnit;

  lives_ok {
      AssertThat
          ->document("test.pdf")
          ->hasNumberOfPages(1)
          ;
  } "Document has one page";

...or (nearly everything is possible):

  use Test::More;
  use Test::Exception;
  use PDF::PDFUnit;

  lives_ok {
      my $leftX  =   0;
      my $upperY =  30;
      my $width  = 210;
      my $height = 235;

      my $textBody = PageRegion->new($leftX, $upperY, $width, $height);

      AssertThat
          ->document("test.pl")
          ->restrictedTo(LAST_PAGE)
          ->restrictedTo($textBody)
          ->hasNoImage()
          ->hasNoText()
          ;
  } "Last page body should be empty";

=head1 DESCRIPTION

As mentioned above, I<PDF::PDFUnit> is just a wrapper.
Therefore, we won't repeat
the excellent documentation you can find at
L<http://pdfunit.com/en/documentation/java/>.

Ok, it's Java, but if you find an example like

  @Test
  public void hasOnePage_en() throws Exception {
    String filename = "test.pdf";

    AssertThat.document(filename)
              .hasNumberOfPages(1)
    ;
  }

it should not be too hard to translate it into the I<real> language:

  lives_ok {
      my $filename = "test.pdf";

      AssertThat
          ->document($filename)
          ->hasNumberOfPages(1)
          ;
  } "Document has one page";


Every method call behind C<AssertThat> is essentially one test. But typically
you will use the very convenient
L<fluent interface|https://en.wikipedia.org/wiki/Fluent_interface>.




=head1 TESTING

The Java people throw exceptions when their tests fail. Like it or not,
I<PDF::PDFUnit> does the same for technical reasons.

Occasionally you want to peek into the thrown C<PDFUnitValidationException>
object, because it should contain a helpful message.

Under I<Test::More>, you could do something like

  diag $@->getMessage() if $@;

Just use C<print> or C<say> otherwise.


=head1 IMPORT TAGS

I<PDF::PDFUnit> knows two import tags. Both of them are not intended for
public use:

=over 4

B<:skip_on_error>

This is intended for the distribution tests: If something fails during
initialization, then all tests will be skipped. (Trivial case: No
configuration file available.)

B<:noinit>

Use this if you want to start the initialization process later. At some
point you could then call

  PDF::PDFUnit->init();

or even instead

  PDF::PDFUnit->load_config();
  PDF::PDFUnit->build_classpath();
  PDF::PDFUnit->attach_java();

L<pdfunit-perl.pl> uses this. You will probably never need it.

=back

=head1 AUTHOR

Axel Miesen <miesen@quadraginta-duo.de>

=head1 THANKS TO

Carsten Siedentop <info@pdfunit.com> for writing PDFUnit-Java

=head1 SEE ALSO

L<Inline::Java>, L<B<PDFUnit>|http://pdfunit.com/>
