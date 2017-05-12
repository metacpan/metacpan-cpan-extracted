package Padre::Plugin::Perl6::QuickFix;
BEGIN {
  $Padre::Plugin::Perl6::QuickFix::VERSION = '0.71';
}

# ABSTRACT: Padre Perl 6 Quick Fix Provider
use 5.008;
use strict;
use warnings;

use Padre::Wx                  ();
use Padre::Plugin::Perl6::Util ();
use Padre::QuickFix            ();

our @ISA = ('Padre::QuickFix');

#
# Constructor.
# No need to override this
#
sub new {
	my ($class) = @_;

	# Create myself :)
	my $self = bless {}, $class;

	return $self;
}

#
# Tries to find quick fixes for errors in the current line
#
sub quick_fix_list {
	my ( $self, $doc, $editor ) = @_;

	if ( not defined $doc->{issues} ) {
		$doc->{issues} = [];
	}

	my $nl              = Padre::Plugin::Perl6::Util::guess_newline( $editor->GetText );
	my $current_line_no = $editor->GetCurrentLine;

	my @items      = ();
	my $num_issues = scalar @{ $doc->{issues} };
	foreach my $issue ( @{ $doc->{issues} } ) {
		my $issue_line_no = $issue->{line} - 1;
		if ( $issue_line_no == $current_line_no ) {
			my $issue_msg = $issue->{msg};
			$issue_msg =~ s/^\s+|\s+$//g;
			if ( $issue_msg =~ /^Variable\s+(.+?)\s+is not predeclared at/i ) {

				my $var_name = $1;

				# Fixes the following:
				# 	$foo = 1;
				# into:
				# 	my $foo;
				#	$foo = 1;
				push @items, {
					text     => sprintf( Wx::gettext('Insert declaration for %s'), $var_name ),
					listener => sub {

						#Insert a variable declaration before the start of the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						my $indent     = ( $line_text =~ /(^\s+)/ ) ? $1 : '';
						$line_text = "${indent}my $var_name;$nl" . $line_text;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Undeclared routine:\s+(.+?)\s+used/i ) {

				my $routine_name = $1;

				#flow control keywords
				my @flow_control_keywords = (
					'for',    'given', 'if',   'loop', 'repeat',
					'unless', 'until', 'when', 'while',
				);
				foreach my $keyword (@flow_control_keywords) {
					if ( $keyword eq $routine_name ) {

						# Fixes the following:
						# 	if() { };
						# into:
						# 	if () { };
						push @items, {
							text     => sprintf( Wx::gettext('Insert a space after %s'), $keyword ),
							listener => sub {

								#Insert a space before brace
								my $line_start = $editor->PositionFromLine($current_line_no);
								my $line_end   = $editor->GetLineEndPosition($current_line_no);
								my $line_text  = $editor->GetTextRange( $line_start, $line_end );
								$line_text =~ s/$keyword\(/$keyword \(/;
								$editor->SetSelection( $line_start, $line_end );
								$editor->ReplaceSelection($line_text);
							},
						};

						last;
					}
				}

				# Fixes the following:
				# 	foo();
				# into:
				# 	sub foo() {
				#		#XXX-implement
				# 	}
				# 	foo();
				push @items, {
					text     => sprintf( Wx::gettext('Insert routine %s'), $routine_name ),
					listener => sub {

						#Insert an empty routine definition before the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						my $indent     = ( $line_text =~ /(^\s+)/ ) ? $1 : '';
						$line_text =
							  "${indent}sub $routine_name {$nl"
							. "${indent}\t#XXX-implement$nl"
							. "${indent}}$nl"
							. $line_text;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Obsolete use of . to concatenate strings/i ) {

				# Fixes the following:
				# 	$string = "a" . "b";
				# into:
				# 	$string = "a" ~ "b";
				push @items, {
					text     => Wx::gettext('Use ~ instead of . for string concatenation'),
					listener => sub {

						#replace first '.' with '~' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\./~/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Obsolete use of -> to call a method/i ) {

				# Fixes the following:
				# 	P->foo;
				# into:
				# 	P.foo;
				push @items, {
					text     => Wx::gettext('Use . for method call'),
					listener => sub {

						#Replace first '->' with '.' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\-\>/\./;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Obsolete use of C\+\+ constructor syntax/i ) {

				# Fixes the following:
				# 	new Foo;
				# into:
				# 	Foo.new;
				push @items, {
					text     => Wx::gettext('Use Perl 6 constructor syntax'),
					listener => sub {

						#Replace first 'new Foo' with 'Foo.new' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );

						#new Point/new Point::Bar/new Point-In-Box
						$line_text =~ s/new\s+([\w\-\:\:]+)?/$1.new/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Obsolete use of C-style "for \(;;\)" loop/i ) {

				# Fixes the following:
				# 	for(;;) { };
				# into:
				# 	loop(;;) { };
				push @items, {
					text     => Wx::gettext('Use loop (;;) for looping'),
					listener => sub {

						#Replace first 'for (;;)' with 'loop (;;)' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/for\s+\(/loop (/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Obsolete use of \[-1\] subscript to access final element/i ) {

				# Fixes the following:
				# 	[-1];
				# into:
				# 	[*-1];
				push @items, {
					text     => Wx::gettext('Use [*-1] to access final element'),
					listener => sub {

						#Replace first '[-1]' with '[*-1]' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\[\s*-1\s*\]/[*-1]/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Obsolete use of rand\(N\)/i ) {

				# Fixes the following:
				# 	rand(10);
				# into:
				# 	10.pick;
				push @items, {
					text     => Wx::gettext('Use N.pick for a random number'),
					listener => sub {

						#Replace rand(N) with N.pick' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/rand\s*\(\s*(.+?)\s*\)/$1.pick/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

				# Fixes the following:
				# 	rand(10);
				# into:
				# 	(1..10).pick;
				push @items, {
					text     => Wx::gettext('Use (1..N).pick for a random number'),
					listener => sub {

						#Replace rand(N) with (1..N).pick' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/rand\s*\(\s*(.+?)\s*\)/(1..$1).pick/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Please use \.\.\* for indefinite range/i ) {

				# Fixes the following:
				# 	[1..];
				# into:
				# 	[1..*];
				push @items, {
					text     => Wx::gettext('Use [N..*] for indefinite range'),
					listener => sub {

						#Replace first '[1..]' with '[1..*]' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\[\s*(.+?)\.\.\s*\]/\[$1..*\]/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Please use \!\! rather than \:\:/i ) {

				# Fixes the following:
				# 	1 == 2 ?? 1 :: 2;
				# into:
				# 	1 == 2 ?? 1 !! 2;
				push @items, {
					text     => Wx::gettext('Use !! for conditional operator'),
					listener => sub {

						#Replace first '!!' with '::' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\:\:/!!/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Precedence too loose within \?\?\!\!/i ) {

				# Fixes errors like:
				# 	42 ?? 1,2,3 Z 4,5,6 !! 1,2,3 X 4,5,6;
				# into:
				# 	42 ?? (1,2,3 Z 4,5,6) !! 1,2,3 X 4,5,6;
				push @items, {
					text     => Wx::gettext('Use ?? (...) !! to avoid precedence bugs'),
					listener => sub {

						#Replace '?? ... !!' with '?? (...) !!' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );

						#XXX- handle multiple lines...
						$line_text =~ s/\?\?(.+?)\!\!/??($1)!!/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Obsolete use of \?\: for the conditional operator/i ) {

				# Fixes the following:
				# 	(1 == 1) ? 1 : 2
				# into:
				# 	(1 == 1) ?? 1 !! 2
				push @items, {
					text     => Wx::gettext('Use ?? !! for the conditional operator'),
					listener => sub {

						#Replace first '? ... :' with '?? ... !!' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\?\s*(.+?)\s*\:/?? $1 !!/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Possible obsolete use of \.\= as append operator/i ) {

				# Fixes the following:
				# 	$string .= "a";
				# into:
				# 	$string ~= "a";
				push @items, {
					text     => Wx::gettext('Use ~= for string concatenation'),
					listener => sub {

						#Replace first '=.' with '=~' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\.\=/~=/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Obsolete use of \=\~ to do pattern matching/i ) {

				# Fixes the following:
				# 	$string =~ /abc/;
				# into:
				# 	$string ~~ /abc/;
				push @items, {
					text     => Wx::gettext('Use ~~ for pattern matching'),
					listener => sub {

						#Replace first '=.' with '=~' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\=\~/~~/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Obsolete use of \!\~ to do negated pattern matching/i ) {

				# Fixes the following:
				# 	$string !~ /abc/;
				# into:
				# 	$string !~~ /abc/;
				push @items, {
					text     => Wx::gettext('Use !~~ for negated pattern matching'),
					listener => sub {

						#Replace first '!~' with '!~~' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\!\~/!~~/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Obsolete use of >> to do right shift/i ) {

				# Fixes the following:
				# 	2 >> 1;
				# into:
				# 	2 +> 1;
				push @items, {
					text     => Wx::gettext('Use +> for numeric right shift'),
					listener => sub {

						#Replace first '>>' with '+>' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\>\>/+>/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

				# Fixes the following:
				# 	100 >> 1;
				# into:
				# 	100 ~> 1;
				push @items, {
					text     => Wx::gettext('Use ~> for string right shift'),
					listener => sub {

						#Replace first '>>' with '~>' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\>\>/~>/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};
			} elsif ( $issue_msg =~ /^Obsolete use of << to do left shift/i ) {

				# Fixes the following:
				# 	2 << 1;
				# into:
				# 	2 +< 1;
				push @items, {
					text     => Wx::gettext('Use +< for numeric left shift'),
					listener => sub {

						#Replace first '<<' with '+<' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\<\</+</;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

				# Fixes the following:
				# 	100 << 1;
				# into:
				# 	100 ~< 1;
				push @items, {
					text     => Wx::gettext('Use ~< for string left shift'),
					listener => sub {

						#Replace first '<<' with '~<' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\<\</~</;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Obsolete use of \$\@ variable as eval error/i ) {

				# Fixes the following:
				# 	$@;
				# into:
				# 	$!;
				push @items, {
					text     => Wx::gettext('Use $! for eval errors'),
					listener => sub {

						#Replace first '$@' with '$!' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\$\@/\$!/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Obsolete use of \$\] variable/i ) {

				# Fixes the following:
				# 	$];
				# into:
				# 	$::PERL_VERSION;
				push @items, {
					text     => Wx::gettext('Use $::PERL_VERSION'),
					listener => sub {

						#Replace first '$]' with '$::PERL_VERSION' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\$\]/\$::PERL_VERSION/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			}

		}

	}

	if ($num_issues) {

		# add "comment error line" as the last resort to solving an issue
		foreach my $issue ( @{ $doc->{issues} } ) {
			my $issue_line_no = $issue->{line} - 1;
			if ( $issue_line_no == $current_line_no ) {

				# Fixes the following:
				# 	some_weird_error();
				# into:
				# 	# some_weird_error();
				push @items, {
					text     => Wx::gettext('Comment error line'),
					listener => sub {

						# comment current error by putting a hash and a space
						# since #( is an embedded comment in Perl 6! see S02:166
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text = "# ${line_text}";
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};
				last;
			}
		}

	} else {

		# No issues; let us provide a some helpful quick fixes
		my $selected_text = $editor->GetSelectedText;
		if ( $selected_text && $selected_text =~ /[\n\r]/ ) {

			# Fixes the following:
			# 	faulty_code();
			# into:
			# 	try {
			#		faulty_code();
			#
			#		CATCH {
			#			warn "oops: $!";
			#		}
			#	}

			push @items, {
				text     => Wx::gettext('Surround with try { ... }'),
				listener => sub {

					# Surround the 'selection' with a try { 'selection'  CATCH { } }
					my $line_start =
						$editor->PositionFromLine( $editor->LineFromPosition( $editor->GetSelectionStart ) );
					my $line_end = $editor->PositionFromLine( $editor->LineFromPosition( $editor->GetSelectionEnd ) );

					my $indent = ( $selected_text =~ /(^\s+)/ ) ? $1 : '';
					$selected_text =~ s/^/\t/gm;
					my $line_text =
						  "${indent}try {$nl"
						. "$selected_text$nl"
						. "${indent}\tCATCH {$nl"
						. "${indent}\t\twarn \"oops: \$!\";$nl"
						. "${indent}\t}$nl"
						. "${indent}}$nl";
					$editor->SetSelection( $line_start, $line_end );
					$editor->ReplaceSelection($line_text);
				},
			};

		}

		# Not really a fix but a helper:
		# 	Converts POD6 to XHTML
		push @items, {
			text     => Wx::gettext('Convert POD6 to XHTML'),
			listener => sub {

				# Convert POD6 to XHTML using App::Grok
				my $text = $self->text_get;
				return if not defined $text;

				require File::Temp;
				my $tmp_input = File::Temp->new( SUFFIX => '.p6' );
				binmode( $tmp_input, ":utf8" );
				print $tmp_input $text;
				close $tmp_input or warn "cannot close $tmp_input\n";

				my $main = $editor->main;
				eval {
					require App::Grok;
					my $grok = App::Grok->new;
					my $grok_text = $grok->render_target( $tmp_input->filename, 'xhtml' );

					# create a temporary HTML file
					my $tmp_output = File::Temp->new( SUFFIX => '.html' );
					$tmp_output->unlink_on_destroy(0);
					print $tmp_output $grok_text;
					my $filename = $tmp_output->filename;
					close $tmp_output or warn "Could not close $filename";

					# try to open the HTML file
					$main->setup_editor($filename);

					# launch the HTML file in your default browser
					require URI::file;
					my $file_url = URI::file->new($filename);
					Wx::LaunchDefaultBrowser($file_url);
				};
				if ($@) {
					Wx::MessageBox(
						Wx::gettext('Operation failed!'),
						Wx::gettext('Error'),
						Wx::wxOK,
						$main,
					);
				}
			},
		};

		# Not really a fix but a helper:
		# 	Converts POD6 to Text
		push @items, {
			text     => Wx::gettext('Convert POD6 to Text'),
			listener => sub {

				# Convert POD6 to Text using App::Grok
				my $text = $self->text_get;
				return if not defined $text;

				require File::Temp;
				my $tmp_input = File::Temp->new( SUFFIX => '.p6' );
				binmode( $tmp_input, ":utf8" );
				print $tmp_input $text;
				close $tmp_input or warn "cannot close $tmp_input\n";

				my $main = $editor->main;
				eval {
					require App::Grok;
					my $grok = App::Grok->new;
					my $grok_text = $grok->render_target( $tmp_input->filename, 'text' );

					# create a temporary text file
					my $tmp_output = File::Temp->new( SUFFIX => '.txt' );
					$tmp_output->unlink_on_destroy(0);
					print $tmp_output $grok_text;
					my $filename = $tmp_output->filename;
					close $tmp_output or warn "Could not close $filename";

					# try to open the text file
					$main->setup_editor($filename);
				};
				if ($@) {
					Wx::MessageBox(
						Wx::gettext('Operation failed!'),
						Wx::gettext('Error'),
						Wx::wxOK,
						$main,
					);
				}
			},
		};
	}

	return @items;
}

1;



=pod

=head1 NAME

Padre::Plugin::Perl6::QuickFix - Padre Perl 6 Quick Fix Provider

=head1 VERSION

version 0.71

=head1 DESCRIPTION

Perl 6 quick fixes are implemented here

=head1 AUTHORS

=over 4

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=item *

Gabor Szabo L<http://szabgab.com/>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ahmad M. Zawawi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

