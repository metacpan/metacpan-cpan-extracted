package String::Validator::Language;
$String::Validator::Language::VERSION = '2.00';
# ABSTRACT: Languages for String::Validator

use 5.008;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Validator::Language - Languages for String::Validator

=head1 VERSION

version 2.00

=head1 SYNOPSIS

 my $TranslatedValidator =
     String::Validator::SomeValidator->new(
         language=> String::Validator::Language::CHACKOBSA->new );

=head1 String::Validator::Language

Provides Language Customizations for String Validator

=head1 LANGUAGES AVAILABLE

 LANGUAGE | MODULE                              | Supported Modules
 ---------|-------------------------------------|-----------------------------
 French   | String::Validator::Language::FR     | common, password
 English  | String::Validator::Language::EN     | *

=head2 Language::EN

English is the default language, all of the messages from all of the modules
are in English, use it as a template for Language Customization when creating
new Language Modules.

=head1 Acknowledgements

French translation submitted by Antoine Gallavardin.

=cut

=head1 AUTHOR

John Karr <brainbuz@brainbuz.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by John Karr.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
