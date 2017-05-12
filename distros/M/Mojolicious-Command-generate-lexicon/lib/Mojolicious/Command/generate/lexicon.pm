package Mojolicious::Command::generate::lexicon;

use strict;
use warnings;
use utf8;

use Mojo::Base 'Mojolicious::Command';
use String::Escape qw(qqbackslash);

our $VERSION = 0.997;

use File::Find;
use Getopt::Long;

use MojoX::I18N::Lexemes;

__PACKAGE__->attr(description => <<'EOF');
Generate lexicon file from templates.
EOF

__PACKAGE__->attr(usage => <<"EOF");
usage: $0 generate lexicon [language] [--behavior=save||reset] [templates]
Options:
  -b, --behavior=BEHAVIOR
        Determine how to work with existent lexems, possible values:
            save    save old lexicon values;
            reset   delete old lexicon.
EOF

sub run {
    my $self     = shift;
    my $language = shift;

    my @templates;
    my $app;
    if (ref $self->app eq 'CODE'){
        $app = $self->app->();
    }
    else{
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
        'verbose|v:1'        => \$verbose,
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

    my $lexem_file = $app->home->rel_file("lib/$app_class/I18N/$language.pm");
    my %oldlex     = ();

    if (-e $lexem_file) {
        if ($language ne 'Skeleton') {
            if (lc $behavior eq 'save') {
                %oldlex = eval {
                    local %INC = %INC;
                    require $app->home->rel_file("lib/$app_class/I18N/$language.pm");
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
    $self->render_to_file('package', $lexem_file, $app_klass, $language,
        \%lexicon);
}

1;

__DATA__
@@ package
% my ($app_class, $language, $lexicon) = @_;
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

    $ ./script/my_mojolicious_app generate lexicon [language]
        [--behavior=save||reset] [templates]

Or as perl module

    use Mojolicious::Command::generate::lexicon;

    my $l = Mojolicious::Command::generate::lexicon->new;
    $inflate->run($language, @files);


=head1 SEE ALSO

L<MojoX::I18N::Lexemes>

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/und3f/mojolicious-lexicon

=head1 AUTHOR

Sergey Zasenko, C<undef@cpan.org>.

=head1 CREDITS

In alphabetical order

=over 2

Silvio

Tetsuya Tatsumi

=back

=head1 COPYRIGHT

Copyright (C) 2011-2016, Sergey Zasenko

This program is free software, you can redistribute it and/or modify it
under the terms of the Artistic License version 2.0.

=cut
