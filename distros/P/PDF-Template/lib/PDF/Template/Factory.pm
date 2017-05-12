package PDF::Template::Factory;

use strict;

BEGIN {
    use vars qw(%Manifest %isBuildable);
}

%Manifest = (

# These are the instantiable nodes
    'ALWAYS'      => 'PDF::Template::Container::Always',
    'CONDITIONAL' => 'PDF::Template::Container::Conditional',
    'FONT'        => 'PDF::Template::Container::Font',
    'IF'          => 'PDF::Template::Container::Conditional',
    'LOOP'        => 'PDF::Template::Container::Loop',
    'PAGEDEF'     => 'PDF::Template::Container::PageDef',
    'PDFTEMPLATE' => 'PDF::Template::Container::PdfTemplate',
    'ROW'         => 'PDF::Template::Container::Row',
    'SCOPE'       => 'PDF::Template::Container::Scope',
    'SECTION'     => 'PDF::Template::Container::Section',
    'HEADER'      => 'PDF::Template::Container::Header',
    'FOOTER'      => 'PDF::Template::Container::Footer',

    'BOOKMARK'    => 'PDF::Template::Element::Bookmark',
    'CIRCLE'      => 'PDF::Template::Element::Circle',
    'HR'          => 'PDF::Template::Element::HorizontalRule',
    'IMAGE'       => 'PDF::Template::Element::Image',
    'PAGEBREAK'   => 'PDF::Template::Element::PageBreak',
    'LINE'        => 'PDF::Template::Element::Line',
    'TEXTBOX'     => 'PDF::Template::Element::TextBox',
    'VAR'         => 'PDF::Template::Element::Var',
    'WEBLINK'     => 'PDF::Template::Element::Weblink',

# These are the helper objects

    'TEXTOBJECT' => 'PDF::Template::TextObject',
    'CONTEXT'    => 'PDF::Template::Context',
    'ITERATOR'   => 'PDF::Template::Iterator',

    'MARGIN'     => 'PDF::Template::Container::Margin',

    'CONTAINER'  => 'PDF::Template::Container',
    'ELEMENT'    => 'PDF::Template::Element',

    'BASE'       => 'PDF::Template::Base',
);

%isBuildable = map { $_ => 1 } qw(
    ALWAYS
    BOOKMARK
    CIRCLE
    CONDITIONAL
    FONT
    FOOTER
    HEADER
    HR
    IF
    IMAGE
    LINE
    LOOP
    PAGEBREAK
    PAGEDEF
    PDFTEMPLATE
    ROW
    SCOPE
    SECTION
    TEXTBOX
    VAR
    WEBLINK
);

sub register
{
    my %params = @_;

    my @param_names = qw(name class isa);
    for (@param_names)
    {
        unless ($params{$_})
        {
            warn "$_ was not supplied to register()\n";
            return 0;
        }
    }

    my $name = uc $params{name};
    if (exists $Manifest{$name})
    {
        warn "$params{name} already exists in the manifest.\n";
        return 0;
    }

    my $isa = uc $params{isa};
    unless (exists $Manifest{$isa})
    {
        warn "$params{isa} does not exist in the manifest.\n";
        return 0;
    }

    $Manifest{$name} = $params{class};
    $isBuildable{$name} = 1;

    {
        no strict 'refs';
        unshift @{"$params{class}::ISA"}, $Manifest{$isa};
    }

    return 1;
}

sub create
{
    my $class = shift;
    my $name = uc shift;

    return unless exists $Manifest{$name};

    (my $filename = $Manifest{$name}) =~ s!::!/!g;

    eval {
        require "$filename.pm";
    }; if ($@) {
        die "Cannot find or compile PM file for '$name' ($filename)\n";
    }

    return $Manifest{$name}->new(@_);
}

sub create_node
{
    my $class = shift;
    my $name = uc shift;

    return unless exists $isBuildable{$name};

    return $class->create($name, @_);
}

sub isa
{
    return UNIVERSAL::isa($_[0], $Manifest{uc $_[1]})
        if @_ >= 2 && exists $Manifest{uc $_[1]};

    UNIVERSAL::isa(@_)
}

1;
__END__
