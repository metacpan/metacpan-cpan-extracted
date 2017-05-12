package RT::Extension::CustomField::Checkbox;

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.04';

=head1 NAME

RT::Extension::CustomField::Checkbox (DEPRECATED) - extension for RT to add checkboxes and radio buttons based custom fields

=head1 DESCRIPTION

Install it, register within @Plugins in the config. Enjoy.

=head1 ATTENTION FOR USERS OF RT 4.0

You don't need this extension. RT 4.0 and newer has this
functionality build in.

RT 4.0.20 and 4.2.3 ship etc/upgrade/4.0-customfield-checkbox-extension
which can upgrade these custom fields to be compatible with the RT 4.0 core feature.

=cut

# code goes here

die "\n\nYou don't need this extension. RT 4.0 and newer has this functionality build in. Read documentation for upgrade instructions.\n\n"
    if $RT::VERSION =~ /^[4-9]\./;

use RT::CustomField;
$RT::CustomField::FieldTypes{'SelectCheckbox'} = [
    'Check multiple values',    # loc
    'Check one value',           # loc
    'Check up to [_1] values',  # loc
];


=head1 AUTHOR

Ruslan Zakirov E<lt>Ruslan.Zakirov@gmail.comE<gt>

=head1 LICENSE

Under the same terms as perl itself.

=cut

1;
