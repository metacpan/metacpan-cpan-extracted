package Mo::utils::Unicode;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use List::Util 1.33 qw(none);
use Mo::utils 0.06 qw(check_array);
use Readonly;
use Unicode::UCD qw(charblocks charscripts);

Readonly::Array our @EXPORT_OK => qw(check_array_unicode_block check_unicode_block check_unicode_script);

our $VERSION = 0.01;

sub check_array_unicode_block {
	my ($self, $key) = @_;

	if (! exists $self->{$key}) {
		return;
	}

	check_array($self, $key);

	foreach my $unicode_block (@{$self->{$key}}) {
		_check_unicode_block($unicode_block, $key);
	}

	return;
}

sub check_unicode_block {
	my ($self, $key) = @_;

	if (! exists $self->{$key}) {
		return;
	}

	_check_unicode_block($self->{$key}, $key);

	return;
}

sub check_unicode_script {
	my ($self, $key) = @_;

	if (! exists $self->{$key}) {
		return;
	}

	if (none { $self->{$key} eq $_ } keys %{charscripts()}) {
		err "Parameter '".$key."' contains invalid Unicode script.",
			'Value', $self->{$key},
		;
	}

	return;
}

sub _check_unicode_block {
	my ($value, $key) = @_;

	if (none { $value eq $_ } keys %{charblocks()}) {
		err "Parameter '".$key."' contains invalid Unicode block.",
			'Value', $value,
		;
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Mo::utils::Unicode - Mo utilities for Unicode.

=head1 SYNOPSIS

 use Mo::utils::Unicode qw(check_array_unicode_block check_unicode_block check_unicode_script);

 check_array_unicode_block($self, $key);
 check_unicode_block($self, $key);
 check_unicode_script($self, $key);

=head1 DESCRIPTION

Mo utilities for Unicode checking of data objects.

=head1 SUBROUTINES

=head2 C<check_array_unicode_block>

 check_array_unicode_block($self, $key);

Check parameter defined by C<$key> which is valid array with Unicode block names.

Put error if check isn't ok.

Returns undef.

=head2 C<check_unicode_block>

 check_unicode_block($self, $key);

Check parameter defined by C<$key> which is valid Unicode block name.

Put error if check isn't ok.

Returns undef.

=head2 C<check_unicode_script>

 check_unicode_script($self, $key);

Check parameter defined by C<$key> which is valid Unicode script name.

Put error if check isn't ok.

Returns undef.

=head1 ERRORS

 check_array_unicode_block():
         From Mo::utils::check_array():
                 Parameter '%s' must be a array.
                         Value: %s
                         Reference: %s
         Parameter '%s' contains invalid Unicode block.
                 Value: %s
 check_unicode_block():
         Parameter '%s' contains invalid Unicode block.
                 Value: %s
 check_unicode_script():
         Parameter '%s' contains invalid Unicode script.
                 Value: %s

=head1 EXAMPLE1

=for comment filename=check_array_unicode_block_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Unicode qw(check_array_unicode_block);

 my $self = {
         'key' => [
                 'Latin Extended-A',
                 'Latin Extended-B',
         ],
 };
 check_array_unicode_block($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE2

=for comment filename=check_array_unicode_block_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::Unicode qw(check_array_unicode_block);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => [
                'Bad Unicode block',
          ],
 };
 check_array_unicode_block($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [..utils.pm:?] Parameter 'key' contains invalid Unicode block.

=head1 EXAMPLE3

=for comment filename=check_unicode_block_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Unicode qw(check_unicode_block);

 my $self = {
         'key' => 'Latin Extended-A',
 };
 check_unicode_block($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE4

=for comment filename=check_unicode_block_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::Unicode qw(check_unicode_block);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'Bad Unicode block',
 };
 check_unicode_block($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [..utils.pm:?] Parameter 'key' contains invalid Unicode block.

=head1 EXAMPLE5

=for comment filename=check_unicode_script_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Unicode qw(check_unicode_script);

 my $self = {
         'key' => 'Thai',
 };
 check_unicode_script($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE6

=for comment filename=check_unicode_script_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::Unicode qw(check_unicode_script);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'bad_script',
 };
 check_unicode_script($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [..utils.pm:?] Parameter 'key' contains invalid Unicode script.

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<List::Util>,
L<Mo::utils>
L<Readonly>,
L<Unicode::UCD>.

=head1 SEE ALSO

=over

=item L<Mo>

Micro Objects. Mo is less.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Mo-utils-Unicode>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
