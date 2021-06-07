package Pod::Weaver::Plugin::ArrayData;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-20'; # DATE
our $DIST = 'Pod-Weaver-Plugin-ArrayData'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

use File::Slurper qw(write_text);
use File::Temp qw(tempfile);
use List::Util qw(first);
use Perinci::Result::Format::Lite;

sub _md2pod {
    require Markdown::To::POD;

    my ($self, $md) = @_;
    my $pod = Markdown::To::POD::markdown_to_pod($md);
    # make sure we add a couple of blank lines in the end
    $pod =~ s/\s+\z//s;
    $pod . "\n\n\n";
}

sub _process_module {
    no strict 'refs';

    my ($self, $document, $input, $package) = @_;

    my $filename = $input->{filename};

    {
        # we need to load the munged version of module
        my ($temp_fh, $temp_fname) = tempfile();
        my ($file) = grep { $_->name eq $filename } @{ $input->{zilla}->files };
        write_text($temp_fname, $file->content);
        require $temp_fname;
    }

    my $ad = $package->new;

    my $ad_name = $package;
    $ad_name =~ s/\AArrayData:://;
    my ($name_entity, $name_entities, $name_mod, $varname);
    if ($ad_name =~ /^Word::/) {
        $name_entity   = "word";
        $name_entities = "words";
        $name_mod = 'ArrayData::Word';
        $varname = 'wl';
    } elsif ($ad_name =~ /^Phrase::/) {
        $name_entity   = "phrase";
        $name_entities = "phrases";
        $name_mod = 'ArrayData::Phrase';
        $varname = 'pl';
    } else {
        $name_entity   = "element";
        $name_entities = "elements";
        $name_mod = 'ArrayData';
        $varname = 'ary';
    }

  ADD_SYNOPSIS_SECTION:
    {
        my @pod;
        push @pod, " use $package;\n\n";
        push @pod, " my \$$varname = $package->new;\n\n";

        push @pod, " # Iterate the $name_entities\n";
        push @pod, " \$${varname}->reset_iterator;\n";
        push @pod, " while (\$${varname}->has_next_item) {\n";
        push @pod, "     my \$$name_entity = \$${varname}->get_next_item;\n";
        push @pod, "     ... # do something with the $name_entity\n";
        push @pod, " }\n";
        push @pod, "\n";

        push @pod, " # Another way to iterate\n";
        push @pod, " \$$varname\->each_item(sub { my (\$item, \$obj, \$pos) = \@_; ... }); # return false in anonsub to exit early\n";
        push @pod, "\n";

        push @pod, " # Get $name_entities by position (array index)\n";
        push @pod, " my \$$name_entity = \$$varname\->get_item_at_pos(0);  # get the first $name_entity\n";
        push @pod, " my \$$name_entity = \$$varname\->get_item_at_pos(90); # get the 91th $name_entity, will die if there is no $name_entity at that position.\n";
        push @pod, "\n";

        push @pod, " # Get number of $name_entities in the list\n";
        push @pod, " my \$count = \$$varname\->get_item_count;\n";
        push @pod, "\n";

        push @pod, " # Get all $name_entities from the list\n";
        push @pod, " my \@all_$name_entities = \$$varname\->get_all_items;\n";
        push @pod, "\n";

        if ($ad->can('has_item')) {
            push @pod, " # Find an item.\n";
        } else {
            push @pod, " # Find an item (by iterating). See Role::TinyCommons::Collection::FindItem::Iterator for more details.\n";
            push @pod, " \$$varname\->apply_roles('FindItem::Iterator'); # or: \$$varname = $package->new->apply_roles(...);\n";
        }
        push @pod, " my \@found = \$$varname\->find_item(item => 'foo');\n";
        push @pod, " my \$has_item = \$$varname\->has_item('foo'); # bool\n";
        push @pod, "\n";

        if ($ad->can('has_item')) {
            push @pod, " # Pick one or several random $name_entities.\n";
        } else {
            push @pod, " # Pick one or several random $name_entities (apply one of these roles first: Role::TinyCommons::Collection::PickItems::{Iterator,RandomPos,RandomSeekLines})\n";
            push @pod, " \$$varname\->apply_roles('PickItems::Iterator'); # or: \$$varname = $package->new->apply_roles(...);\n";
        }
        push @pod, " my \$$name_entity = \$$varname\->pick_item;\n";
        push @pod, " my \@$name_entities = \$$varname\->pick_items(n=>3);\n\n";
        push @pod, "\n";

        $self->add_text_to_section(
            $document, join("", @pod), 'SYNOPSIS',
            {
                after_section => ['VERSION', 'NAME'],
                before_section => 'DESCRIPTION',
                ignore => 1,
            });
    } # ADD_SYNOPSIS_SECTION

  ADD_ARRAYDATA_MODULE_PARAMETERS_SECTION:
    {
        my $meta = $package->can("meta") ? $package->meta : undef;
        last unless $meta;
        my $args_prop = $meta->{args};
        last unless keys %$args_prop;

        my $examples = $meta->{examples};
        my $first_example_with_args = first { $_->{args} && keys %{ $_->{args} } } @$examples;

        my @pod;

        push @pod, <<_;

This is a parameterized $name_mod module. When loading in Perl, you can specify
the parameters to the constructor, for example:

 use $package;
_
        my $args;
        if ($first_example_with_args) {
            my $eg = $first_example_with_args;
            push @pod, " # $eg->{summary}\n" if defined $eg->{summary};
            $args = $eg->{args};
        } else {
            $args = {foo=>1, bar=>2};
        }

        push @pod, " my \$$varname = $package\->(".
            join(", ", map {"$_ => $args->{$_}"} sort keys %$args).");\n\n";

        push @pod, <<_;

When loading on the command-line, you can specify parameters using the
C<ARRAYDATAMODNAME=ARGNAME1,ARGVAL1,ARGNAME2,ARGVAL2> syntax, like in L<perl>'s
C<-M> option, for example:

_

        if ($first_example_with_args) {
            my $eg = $first_example_with_args;
            push @pod, " % arraydata -m $ad_name=",
                join(",", map { "$_=$eg->{args}{$_}" } sort keys %{ $eg->{args} }), "\n\n";
        } else {
            push @pod, " % arraydata -m $ad_name=foo,1,bar,2 ...\n\n";
        }

        push @pod, "Known parameters:\n\n";
        for my $argname (sort keys %$args) {
            my $argspec = $args->{$argname};
            push @pod, "=head2 $argname\n\n";
            push @pod, "Required. " if $argspec->{req};
            if (defined $argspec->{summary}) {
                require String::PodQuote;
                push @pod, String::PodQuote::pod_quote($argspec->{summary}), ".\n\n";
            }
            push @pod, $self->_md2pod($argspec->{description})
                if $argspec->{description};
        }

        $self->add_text_to_section(
            $document, join("", @pod), 'ARRAYDATA MODULE PARAMETERS',
            {
                after_section => 'DESCRIPTION',
                ignore => 1,
            });
    } # ADD_ARRAYDATA_MODULE_PARAMETERS_SECTION

  ADD_STATISTICS_SECTION:
    {
        no strict 'refs';
        my @pod;
        my $stats = \%{"$package\::STATS"};
        last unless keys %$stats;
        my $str = Perinci::Result::Format::Lite::format(
            [200,"OK",$stats], "text-pretty");
        $str =~ s/^/ /gm;
        push @pod, $str, "\n";

        push @pod, "The statistics is available in the C<\%STATS> package variable.\n\n";

        $self->add_text_to_section(
            $document, join("", @pod), 'ARRAYDATA MODULE STATISTICS',
            {
                after_section => ['SYNOPSIS'],
                before_section => 'DESCRIPTION',
                ignore => 1,
            });
    } # ADD_STATISTICS_SECTION

    $self->log(["Generated POD for '%s'", $filename]);
}

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename};

    my $package;
    if ($filename =~ m!^lib/(ArrayData/.+)\.pm$!) {
        $package = $1;
        $package =~ s!/!::!g;
        $self->_process_module($document, $input, $package);
    }
}

1;
# ABSTRACT: Plugin to use when building ArrayData::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::ArrayData - Plugin to use when building ArrayData::* distribution

=head1 VERSION

This document describes version 0.003 of Pod::Weaver::Plugin::ArrayData (from Perl distribution Pod-Weaver-Plugin-ArrayData), released on 2021-05-20.

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-ArrayData]

=head1 DESCRIPTION

This plugin is to be used when building C<ArrayData::*> distribution. Currently
it does the following:

=over

=item * Add a Synopsis section (if doesn't already exist) showing how to use the module

=item * Add ArrayData Module Statistics section showing statistics from C<%STATS> (which can be generated by DZP:ArrayData)

=back

=for Pod::Coverage ^(weave_section)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Plugin-ArrayData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Plugin-ArrayData>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Pod-Weaver-Plugin-ArrayData/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<ArrayData>

L<Dist::Zilla::Plugin::ArrayData>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
