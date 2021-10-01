package Mojolicious::Command::generate::lexicon;

use strict;
use warnings;
use utf8;

use Mojo::Base 'Mojolicious::Command';
use String::Escape qw(qqbackslash);

our $VERSION = 0.998;

use File::Find;
use Getopt::Long;

use MojoX::I18N::Lexemes;

has "description" => "Generate lexicon file from templates.";

has "usage" => sub{shift->extract_usage};

sub run {
    my $self     = shift;
    my $language = shift;

    my @templates;
    my $app;
    if (ref $self->app eq 'CODE') {
        $app = $self->app->();
    }
    else {
        $app = $self->app;
    }

    my $verbose;

    my $app_klass = ref $app;
    my $app_class = ref $app;
    $app_class =~ s{::}{/}g;

    $language ||= 'Skeleton';

    my $behavior = '';

    local @ARGV = @_ if @_;

    my $result = GetOptions(
        "behavior|b:s{1,1}" => \$behavior,
        'verbose|v:1'       => \$verbose,
    );
    push @templates, $ARGV[0] if (defined $ARGV[0]);

    my $handler = $app->renderer->default_handler;

    # Find all templates of project
    unless (@templates) {
        find(
            sub {
                push @templates, $File::Find::name if (/\.$handler/);
            },
            @{$app->renderer->paths}
        );
    }

    my $lexem_file =
      $app->home->rel_file("lib/$app_class/I18N/$language.pm")->to_abs()
      ->to_string();
    my %oldlex = ();

    if (-e $lexem_file) {
        if ($language ne 'Skeleton') {
            if (lc $behavior eq 'save') {
                %oldlex = eval {
                    local %INC = %INC;
                    require $app->home->rel_file(
                        "lib/$app_class/I18N/$language.pm");
                    no strict 'refs';
                    %{*{"${app_klass}::I18N::${language}::Lexicon"}};
                };
                %oldlex = () if ($@);
            }
            elsif (lc $behavior eq 'reset') {

                # Just proceed
            }
            else {
                print <<USAGE;
Lexemes already exists.
You must set `--behavior' to one of "reset" or "save".
USAGE
                return;
            }
        }

        print "  [delete] $lexem_file\n" unless $self->quiet;
        unlink $lexem_file;
    }

    my $l = MojoX::I18N::Lexemes->new();

    my %lexicon = %oldlex;

    foreach my $file (@templates) {
        open F, $file or die "Unable to open $file: $!";
        my $t = do { local $/; <F> };
        close F;

        # get lexemes
        print "Parsing $file \n" if $verbose;
        my $parsed_lexemes = $l->parse($t);

        # add to all lexemes
        foreach (grep { !exists $lexicon{$_} } @{$parsed_lexemes}) {
            $lexicon{$_} = '';
            print "New lexeme found => $_\n" if $verbose;
        }
    }

    # Output lexem
    $self->render_to_file(
        'package',
        $lexem_file, {
            app_class => $app_klass,
            language  => $language,
            lexicon   => \%lexicon
        }
    );
}

1;

__DATA__
@@ package
package <%= $app_class %>::I18N::<%= $language %>;
use base '<%= $app_class %>::I18N';
use utf8;

our %Lexicon = (
% foreach my $lexem (sort keys %$lexicon) {
    % my $lexem_esc = String::Escape::qqbackslash($lexem);
    % my $data = $lexicon->{$lexem} || '';
    % $data  = String::Escape::qqbackslash($data);
    <%= $lexem_esc %> => <%= $data %>,
% }
);

1;

__END__

=head1 NAME

Mojolicious::Command::generate::lexicon - Generate Lexicon Command

=head1 SYNOPSIS

    Usage: APPLICATION generate lexicon [LANGUAGE [OPTIONS [TEMPLATES]]]

    ./script/my_app generate lexicon

    ./script/my_app generate lexicon es -b save

Options:
  -b, --behavior=BEHAVIOR
        Determines how to treat existing lexemes:
            save    save old lexicon values
            reset   delete old lexicon

=head1 SYNOPSIS API

    use Mojolicious::Command::generate::lexicon;

    my $l = Mojolicious::Command::generate::lexicon->new;
    $l->run($language, @files);

=head1 DESCRIPTION

L<Mojolicious::Command::generate::lexicon> generates lexicon files from
existing templates. During template parsing it searches for calls of C<l>, e.g.
C<E<lt>%==l "Hello, world" %E<gt>>. All lexicons are written to
C<lib/MyApp/I18N/E<lt>LANGUAGEE<gt>.pm> files.

=head1 SEE ALSO

L<MojoX::I18N::Lexemes>

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/und3f/mojolicious-lexicon

=head1 AUTHOR

Serhii Zasenko, C<undef@cpan.org>.

=head1 CREDITS

In alphabetical order

=over 2

Silvio

Tetsuya Tatsumi

=back

=head1 COPYRIGHT

Copyright (C) 2011-2021, Serhii Zasenko

This program is free software, you can redistribute it and/or modify it
under the terms of the Artistic License version 2.0.

=cut
