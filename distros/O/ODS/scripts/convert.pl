use strict;
use warnings;

use lib 'lib';

use ODS::Translator;

my ($original_format, $into_format, $original_file) = (shift, shift, shift);

if (!$original_format || !$into_format || !$original_file) {
	die 'use: perl translate.pl $original_format $into_format $original_file';
}

ODS::Translator->new(
	translation => $original_format,
	into_translation => $into_format,
	file => $original_file
)->translate();
