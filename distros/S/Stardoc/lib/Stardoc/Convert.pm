##
# name:      Stardoc::Convert
# abstract:  Convert Stardoc Perl modules to pod
# author:    Ingy döt Net <ingy@cpan.org>
# copyright: 2011
# license:   perl

package Stardoc::Convert;
use Mouse;

use Stardoc::Module::Perl;
use Stardoc::Document::Pod;

sub perl_file_to_pod {
    my ($class, $file) = @_;
    my $mod = Stardoc::Module::Perl->new(file => $file);
    return unless $mod->has_doc;
    my $doc = Stardoc::Document::Pod->new(module => $mod);
    return $doc->format();
}

1;
