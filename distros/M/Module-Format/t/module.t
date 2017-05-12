use strict;
use warnings;

use Test::More tests => 63;

use Module::Format::Module;

{
    my $module = Module::Format::Module->from(
        {
            format => 'colon',
            value => 'XML::Grammar::Fiction',
        }
    );

    # TEST
    ok ($module);

    # TEST
    is_deeply(
        $module->get_components_list(),
        [qw(XML Grammar Fiction)],
        "get_components_list() is sane.",
    );

    # TEST
    is ($module->format_as('colon'), 'XML::Grammar::Fiction',
        "Format as colon is sane."
    );

    # TEST
    is ($module->format_as('dash'), 'XML-Grammar-Fiction',
        "Format as dash is sane.",
    );

    # TEST
    is ($module->format_as('unix'), 'XML/Grammar/Fiction.pm',
        "Format as unix is sane.",
    );

    # TEST
    is ($module->format_as('rpm_dash'), 'perl-XML-Grammar-Fiction',
        "Format as rpm_dash is sane.",
    );

    # TEST
    is ($module->format_as('rpm_colon'), 'perl(XML::Grammar::Fiction)',
        "Format as rpm_colon is sane.",
    );

    # TEST
    is ($module->format_as('debian'), 'libxml-grammar-fiction-perl',
        "Format as debian is sane.",
    );

}

{
    my $module = Module::Format::Module->from(
        {
            format => 'dash',
            value => 'HTML-TreeBuilder-LibXML',
        }
    );

    # TEST
    ok ($module);

    # TEST
    is_deeply(
        $module->get_components_list(),
        [qw(HTML TreeBuilder LibXML)],
        "get_components_list() is sane.",
    );

    # TEST
    is ($module->format_as('colon'), 'HTML::TreeBuilder::LibXML',
        "Format as colon is sane."
    );

    # TEST
    is ($module->format_as('dash'),  'HTML-TreeBuilder-LibXML',
        "Format as dash is sane.",
    );
}

{
    my $module = Module::Format::Module->from(
        {
            format => 'unix',
            value => 'HTML/TreeBuilder/LibXML.pm',
        }
    );

    # TEST
    ok ($module);

    # TEST
    is_deeply(
        $module->get_components_list(),
        [qw(HTML TreeBuilder LibXML)],
        "get_components_list() is sane.",
    );

    # TEST
    is ($module->format_as('colon'), 'HTML::TreeBuilder::LibXML',
        "Format as colon is sane."
    );

    # TEST
    is ($module->format_as('dash'),  'HTML-TreeBuilder-LibXML',
        "Format as dash is sane.",
    );
}

{
    my $module = Module::Format::Module->from(
        {
            format => 'rpm_colon',
            value => 'perl(HTML::TreeBuilder::LibXML)',
        }
    );

    # TEST
    ok ($module);

    # TEST
    is_deeply(
        $module->get_components_list(),
        [qw(HTML TreeBuilder LibXML)],
        "from rpm_colon get_components_list() is sane.",
    );

    # TEST
    is ($module->format_as('colon'), 'HTML::TreeBuilder::LibXML',
        "from rpm_colon Format as colon is sane."
    );

    # TEST
    is ($module->format_as('dash'),  'HTML-TreeBuilder-LibXML',
        "from rpm_colon Format as dash is sane.",
    );
}

{
    my $module = Module::Format::Module->from(
        {
            format => 'rpm_dash',
            value => 'perl-HTML-TreeBuilder-LibXML',
        }
    );

    # TEST
    ok ($module);

    # TEST
    is_deeply(
        $module->get_components_list(),
        [qw(HTML TreeBuilder LibXML)],
        "get_components_list() is sane.",
    );

    # TEST
    is ($module->format_as('colon'), 'HTML::TreeBuilder::LibXML',
        "Format as colon is sane."
    );

    # TEST
    is ($module->format_as('dash'),  'HTML-TreeBuilder-LibXML',
        "Format as dash is sane.",
    );
}

{
    my $orig_module = Module::Format::Module->from(
        {
            format => 'colon',
            value => 'XML::Grammar::Fiction',
        }
    );

    # TEST
    ok ($orig_module, '$orig_module is defined');

    my $clone = $orig_module->clone();

    # TEST
    ok ($clone, '$clone is defined');

    # TEST
    is_deeply(
        $clone->get_components_list(),
        [qw(XML Grammar Fiction)],
        "get_components_list() is sane.",
    );

    # TEST
    is ($clone->format_as('colon'), 'XML::Grammar::Fiction',
        "Format as colon is sane."
    );

    # TEST
    is ($clone->format_as('dash'), 'XML-Grammar-Fiction',
        "Format as dash is sane.",
    );

    # TEST
    is ($clone->format_as('unix'), 'XML/Grammar/Fiction.pm',
        "Format as unix is sane.",
    );

    # TEST
    is ($clone->format_as('rpm_dash'), 'perl-XML-Grammar-Fiction',
        "Format as rpm_dash is sane.",
    );

    # TEST
    is ($clone->format_as('rpm_colon'), 'perl(XML::Grammar::Fiction)',
        "Format as rpm_colon is sane.",
    );

}

{
    my $module = Module::Format::Module->from_components(
        {
            components => [qw(XML Grammar Fiction)],
        }
    );

    # TEST
    ok ($module, '$module is defined');

    # TEST
    ok ($module, '$clone is defined');

    # TEST
    is_deeply(
        $module->get_components_list(),
        [qw(XML Grammar Fiction)],
        "get_components_list() is sane.",
    );

    # TEST
    is ($module->format_as('colon'), 'XML::Grammar::Fiction',
        "Format as colon is sane."
    );

    # TEST
    is ($module->format_as('dash'), 'XML-Grammar-Fiction',
        "Format as dash is sane.",
    );

    # TEST
    is ($module->format_as('unix'), 'XML/Grammar/Fiction.pm',
        "Format as unix is sane.",
    );

    # TEST
    is ($module->format_as('rpm_dash'), 'perl-XML-Grammar-Fiction',
        "Format as rpm_dash is sane.",
    );

    # TEST
    is ($module->format_as('rpm_colon'), 'perl(XML::Grammar::Fiction)',
        "Format as rpm_colon is sane.",
    );
}

{
    my $module = Module::Format::Module->from_components(
        {
            components => [qw(XML Grammar Fiction)],
        }
    );

    # TEST
    ok (scalar($module->is_sane()), "Module is sane.");
}

{
    my $module = Module::Format::Module->from_components(
        {
            components => ['XML', 'F@L',],
        }
    );

    # TEST
    ok (!scalar($module->is_sane()), "Module is not sane.");
}

{
    my $module = Module::Format::Module->from_guess({value => "XML::RSS"});

    # TEST
    ok ($module, "from_guess initialises a module.");

    # TEST
    is_deeply(
        $module->get_components_list(),
        [qw(XML RSS)],
        "from_guess got good components.",
    );
}

{
    my $chosen_format;
    my $module = Module::Format::Module->from_guess(
        {
            value => 'perl(Acme::Hello::Descriptive)',
            format_ref => \$chosen_format,
        }
    );

    # TEST
    ok ($module, "from_guess initialises a module.");

    # TEST
    is_deeply(
        $module->get_components_list(),
        [qw(Acme Hello Descriptive)],
        "from_guess got good components.",
    );

    # TEST
    is ($chosen_format, 'rpm_colon', 'chosen format was initialised');
}

{
    my $chosen_format;
    my $module = Module::Format::Module->from_guess(
        {
            value => 'perl-Acme-Hello-Please',
            format_ref => \$chosen_format,
        }
    );

    # TEST
    ok ($module, "from_guess initialises a module.");

    # TEST
    is_deeply(
        $module->get_components_list(),
        [qw(Acme Hello Please)],
        "from_guess got good components.",
    );

    # TEST
    is ($chosen_format, 'rpm_dash', 'chosen format was initialised');

    # TEST
    is ($module->format_as('dash'), 'Acme-Hello-Please',
        "format_as works for from_guess()ed module",
    );
}

{
    my $chosen_format;
    my $module = Module::Format::Module->from_guess(
        {
            value => 'Acme-Raise-Kwalitee',
            format_ref => \$chosen_format,
        }
    );

    # TEST
    ok ($module, "from_guess initialises a module.");

    # TEST
    is_deeply(
        $module->get_components_list(),
        [qw(Acme Raise Kwalitee)],
        "from_guess got good components.",
    );

    # TEST
    is ($chosen_format, 'dash', 'chosen format was initialised');

    # TEST
    is ($module->format_as('rpm_colon'), 'perl(Acme::Raise::Kwalitee)',
        "format_as works for from_guess()ed module",
    );
}

{
    my $chosen_format;
    my $module = Module::Format::Module->from_guess(
        {
            value => 'Foo::Bar::Baz',
            format_ref => \$chosen_format,
        }
    );

    # TEST
    ok ($module, "from_guess initialises a module.");

    # TEST
    is_deeply(
        $module->get_components_list(),
        [qw(Foo Bar Baz)],
        "from_guess got good components.",
    );

    # TEST
    is ($chosen_format, 'colon', 'chosen format is colon in this case');

    # TEST
    is ($module->format_as('dash'), 'Foo-Bar-Baz',
        "format_as works for from_guess()ed colon module",
    );
}

{
    my $chosen_format;
    my $module = Module::Format::Module->from_guess(
        {
            value => 'MooseX/Role/BuildInstanceOf.pm',
            format_ref => \$chosen_format,
        }
    );

    # TEST
    ok ($module, "from_guess initialises a module.");

    # TEST
    is_deeply(
        $module->get_components_list(),
        [qw(MooseX Role BuildInstanceOf)],
        "from_guess got good components.",
    );

    # TEST
    is ($chosen_format, 'unix', 'chosen format was initialised');

    # TEST
    is ($module->format_as('dash'), 'MooseX-Role-BuildInstanceOf',
        "format_as works for from_guess()ed module",
    );
}
