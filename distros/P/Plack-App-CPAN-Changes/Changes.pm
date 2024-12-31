package Plack::App::CPAN::Changes;

use base qw(Plack::Component::Tags::HTML);
use strict;
use warnings;

use Plack::Util::Accessor qw(changes generator title);
use Tags::HTML::CPAN::Changes 0.06;

our $VERSION = 0.05;

sub _css {
	my ($self, $env) = @_;

	$self->{'_tags_changes'}->process_css;

	return;
}

sub _prepare_app {
	my $self = shift;

	# Defaults which rewrite defaults in module which I am inheriting.
	if (! defined $self->generator) {
		$self->generator(__PACKAGE__.'; Version: '.$VERSION);
	}

	if (! defined $self->title) {
		$self->title('Changes');
	}

	# Inherite defaults.
	$self->SUPER::_prepare_app;

	# Defaults from this module.
	$self->{'_tags_changes'} = Tags::HTML::CPAN::Changes->new(
		'css' => $self->css,
		'tags' => $self->tags,
	);

	# Set CPAN::Changes object to present.
	if (defined $self->changes) {
		$self->{'_tags_changes'}->init($self->changes);
	}

	return;
}

sub _tags_middle {
	my ($self, $env) = @_;

	$self->{'_tags_changes'}->process;

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Plack::App::CPAN::Changes - Plack application to view CPAN::Changes object.

=head1 SYNOPSIS

 use Plack::App::CPAN::Changes;

 my $obj = Plack::App::CPAN::Changes->new(%parameters);
 my $psgi_ar = $obj->call($env);
 my $app = $obj->to_app;

=head1 DESCRIPTION

Plack application which prints changelog record. Record is defined by
L<CPAN::Changes> object, which is created from some file (like Changes) in CPAN distribution.

=head1 METHODS

=head2 C<new>

 my $obj = Plack::App::CPAN::Changes->new(%parameters);

Constructor.

=over 8

=item * C<changes>

Set L<CPAN::Changes> object.

Minimal version of object is 0.500002.

It's optional.

Default value is undef.

=item * C<css>

Instance of L<CSS::Struct::Output> object.

Default value is L<CSS::Struct::Output::Raw> instance.

=item * C<generator>

HTML generator string.

Default value is 'Plack::App::CPAN::Changes; Version: __VERSION__'

=item * C<tags>

Instance of L<Tags::Output> object.

Default value is L<Tags::Output::Raw>->new('xml' => 1) instance.

=item * C<title>

Page title.

Default value is 'Changes'.

=back

Returns instance of object.

=head2 C<call>

 my $psgi_ar = $obj->call($env);

Implementation of view page.

Returns reference to array (PSGI structure).

=head2 C<to_app>

 my $app = $obj->to_app;

Creates L<Plack> application.

Returns L<Plack::Component> object.

=head1 EXAMPLE

=for comment filename=app_changes.pl

 use strict;
 use warnings;

 use CPAN::Changes;
 use CPAN::Changes::Entry;
 use CPAN::Changes::Release;
 use CSS::Struct::Output::Indent;
 use Plack::App::CPAN::Changes;
 use Plack::Runner;
 use Tags::Output::Indent;

 my $changes = CPAN::Changes->new(
         'preamble' => 'Revision history for perl module Foo::Bar',
         'releases' => [
                 CPAN::Changes::Release->new(
                         'entries' => [
                                 CPAN::Changes::Entry->new(
                                         'entries' => [
                                                 'item #1',
                                         ],
                                         'text' => '',
                                 ),
                                 CPAN::Changes::Entry->new(
                                         'entries' => [
                                                 'item #2',
                                         ],
                                         'text' => 'Foo',
                                 ),
                         ],
                         'version' => 0.01,
                 ),
         ],
 );

 # Run application.
 my $app = Plack::App::CPAN::Changes->new(
         'css' => CSS::Struct::Output::Indent->new,
         'changes' => $changes,
         'generator' => 'Plack::App::CPAN::Changes',
         'tags' => Tags::Output::Indent->new(
                 'preserved' => ['style'],
                 'xml' => 1,
         ),
 )->to_app;
 Plack::Runner->new->run($app);

 # Output:
 # HTTP::Server::PSGI: Accepting connections at http://0:5000/

 # > curl http://localhost:5000/
 # <!DOCTYPE html>
 # <html lang="en">
 #   <head>
 #     <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
 #     <meta name="generator" content="Plack::App::CPAN::Changes" />
 #     <meta name="viewport" content="width=device-width, initial-scale=1.0" />
 #     <title>
 #       Changes
 #     </title>
 #     <style type="text/css">
 # * {
 # 	box-sizing: border-box;
 # 	margin: 0;
 # 	padding: 0;
 # }
 # .changes {
 # 	max-width: 800px;
 # 	margin: auto;
 # 	background: #fff;
 # 	padding: 20px;
 # 	border-radius: 8px;
 # 	box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
 # }
 # .changes .version {
 # 	border-bottom: 2px solid #eee;
 # 	padding-bottom: 20px;
 # 	margin-bottom: 20px;
 # }
 # .changes .version:last-child {
 # 	border-bottom: none;
 # }
 # .changes .version h2, .changes .version h3 {
 # 	color: #007BFF;
 # 	margin-top: 0;
 # }
 # .changes .version-changes {
 # 	list-style-type: none;
 # 	padding-left: 0;
 # }
 # .changes .version-change {
 # 	background-color: #f8f9fa;
 # 	margin: 10px 0;
 # 	padding: 10px;
 # 	border-left: 4px solid #007BFF;
 # 	border-radius: 4px;
 # }
 # </style>
 #   </head>
 #   <body>
 #     <div class="changes">
 #       <h1>
 #         Revision history for perl module Foo::Bar
 #       </h1>
 #       <div class="version">
 #         <h2>
 #           0.01
 #         </h2>
 #         <ul class="version-changes">
 #           <li class="version-change">
 #             item #1
 #           </li>
 #           <h3>
 #             [Foo]
 #           </h3>
 #           <li class="version-change">
 #             item #2
 #           </li>
 #         </ul>
 #       </div>
 #     </div>
 #   </body>
 # </html>

=begin html

<a href="https://raw.githubusercontent.com/michal-josef-spacek/Plack-App-CPAN-Changes/master/images/app_changes.png">
  <img src="https://raw.githubusercontent.com/michal-josef-spacek/Plack-App-CPAN-Changes/master/images/app_changes.png" alt="Example screenshot" width="300px" height="300px" />
</a>

=end html

=head1 DEPENDENCIES

L<Plack::Component::Tags::HTML>,
L<Plack::Util::Accessor>,
L<Tags::HTML::CPAN::Changes>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Plack-App-CPAN-Changes>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.05

=cut
