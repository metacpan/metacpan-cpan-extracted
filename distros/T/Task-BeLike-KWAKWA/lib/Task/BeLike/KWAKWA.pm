package Task::BeLike::KWAKWA;

use strict;
use 5.008_005;

our $VERSION = '0.03';

# ABSTRACT: Be more like KWAKWA - use the modules he likes!

1;

__END__

=encoding utf-8

=head1 NAME

Task::BeLike::KWAKWA - Be more like KWAKWA!

=head1 TASK CONTENTS

=head2 Apps

=head3 L<App::Ack>

    # search Perl related files (.pl, .pm, .t)
    $ ack --perl foo

    # search Perl files except .t
    $ echo "--type-add=plpm=.pl,.pm" >> ~/.ackrc
    $ ack --plpm foo

=head3 L<App::ForkProve>

=head3 L<Module::Version> for C<mversion>

    $ mversion Mojolicious
    7.61

=head2 DateTime manipulation

=head3 L<DateTime::Format::ISO8601>

    my $dt = DateTime::Format::ISO8601->parse_datetime('2018-01-01T00:00:00Z');

=head2 Debugging

=head3 L<Reply>

Install L<Term::ReadLine::Gnu>. You'll likely need C<libreadline-dev> or
C<readline-devel> to have actual readline support.

	# ~/.replyrc
    script_line1 = use strict
	script_line2 = use warnings
	script_line3 = use 5.024000

	[Interrupt]
	[FancyPrompt]
	[DataDumper]
	[Colors]
	[ReadLine]
	[Hints]
	[Packages]
	[LexicalPersistence]
	[ResultCache]
	[Autocomplete::Packages]
	[Autocomplete::Lexicals]
	[Autocomplete::Functions]
	[Autocomplete::Globals]
	[Autocomplete::Methods]
	[Autocomplete::Commands]

=head3 L<Pry>

=head2 Filesystem

=head2 L<File::chdir> more sensible way to change directories

=head2 Module management

=head3 L<Pod::Readme>

=head2 Testing

Testing is hard to get right. Consider when writing tests which category the
test falls under and test and organise appropriately. Typically they can be
categorized as integration tests (how major parts of a system work together),
unit tests (exercising modules), functional/user acceptance tests (use case
scenarios, BDD).

Avoid using C<if> statements. If your tests have branches, your tests need
tests.

=head3 L<Test::BDD::Cucumber>

=head3 L<Test::MockTime>

=head3 L<Test::Mojo> can be used to test Dancer2 apps too.

=head3 L<Test2::Suite> use L<Test2::V0>

=head3 L<Test2::Tools::Exception>

=head2 Web

=head3 L<Catalyst>

=head3 L<Dancer2>

=head3 L<Mojolicious>

=head1 AUTHOR

Paul Williams E<lt>kwakwa@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2018- Paul Williams

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Task::BeLike::DAGOLDEN>,
L<Task::BeLike::RJBS>.

=cut
