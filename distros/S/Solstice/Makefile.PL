# Load the Module::Install bundled in ./inc/
use inc::Module::Install;
use Config;

my @non_lib_files = qw(
bin
cgis
conf
examples
javascript
styles
templates
CHANGELOG
content
images
install
lang
LICENSE
t
);

### use Module::Install stuff to build makefile

name            'Solstice';
all_from        'lib/Solstice.pm';
license         'ecl';

requires 'Carp' => 0;
requires 'CGI' => 0;
requires 'CGI::Cookie' => 0;
requires 'CGI::Fast' => 0;
requires 'Class::ISA' => 0;
requires 'Compress::Zlib' => 0;
requires 'Crypt::Rijndael' => 0;
requires 'Crypt::X509' => 0;
requires 'Data::Dumper' => 0;
requires 'Data::FormValidator' => 0;
requires 'Date::Calc' => 0;
requires 'Date::Format' => 0;
requires 'DBI' => 0;
requires 'DBM::Deep' => 0;
requires 'Devel::Symdump' => 0;
requires 'Digest::MD5' => 0;
requires 'Digest::SHA1' => 0;
requires 'Exporter' => 0;
requires 'FCGI' => 0;
requires 'Fcntl' => 0;
requires 'File::MMagic' => 0;
requires 'File::Path' => 0;
requires 'File::stat' => 0;
requires 'HTML::Entities' => 0;
requires 'HTML::Formatter' => 0;
requires 'HTML::FormatText' => 0;
requires 'HTML::Parser' => 0;
requires 'HTML::StripScripts' => 0;
requires 'HTML::TreeBuilder' => 0;
requires 'HTTP::BrowserDetect' => 0;
requires 'Image::Magick' => 0;
requires 'JSON' => 0;
requires 'Mail::Sender' => 0;
requires 'MIME::Base64' => 0;
requires 'Module::Build::Compat' => 0; #this is to prod FormValidator's prereq Image::Size into working
requires 'Sys::Hostname' => 0;
requires 'Time::HiRes' => 0;
requires 'Unicode::String' => 0;
requires 'UNIVERSAL' => 0;
requires 'URI' => 0;
requires 'URI::Escape' => 0;
requires 'XML::LibXML' => 0;

auto_install;
WriteAll();
###################


#modify makefile to include install of solstice resources
my $text = slurpFile('Makefile');
$text =~ s/\ninstall\s*\::/\ninstall :: share_solstice /s;

$text .= "\n\nshare_solstice:\n";
for my $file (@non_lib_files){
    $text .= "\tcp -r $file \$(INST_AUTODIR)/\n";
}

writeFile('Makefile', $text);

### Functions
sub writeFile {
    my $file =  shift;
    my $text = shift;

    open(my $FILE, ">", $file) or die "Couldn't open $file for modification";
    print $FILE $text;
    close $FILE;
}

sub slurpFile {
    my $file = shift;
    my $text;
    {
        local( $/ ) ;
        open( my $fh, "<", $file) or die "Couldn't open $file for modification";
        $text = <$fh>;
        close $fh;
    }
    return $text;
}
