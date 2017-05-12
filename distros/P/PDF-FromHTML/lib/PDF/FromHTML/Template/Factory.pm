package PDF::FromHTML::Template::Factory;

use strict;

BEGIN {
    use vars qw(%Manifest %isBuildable);
}

%Manifest = (

# These are the instantiable nodes
    'ALWAYS'      => 'PDF::FromHTML::Template::Container::Always',
    'CONDITIONAL' => 'PDF::FromHTML::Template::Container::Conditional',
    'FONT'        => 'PDF::FromHTML::Template::Container::Font',
    'IF'          => 'PDF::FromHTML::Template::Container::Conditional',
    'LOOP'        => 'PDF::FromHTML::Template::Container::Loop',
    'PAGEDEF'     => 'PDF::FromHTML::Template::Container::PageDef',
    'PDFTEMPLATE' => 'PDF::FromHTML::Template::Container::PdfTemplate',
    'ROW'         => 'PDF::FromHTML::Template::Container::Row',
    'SCOPE'       => 'PDF::FromHTML::Template::Container::Scope',
    'SECTION'     => 'PDF::FromHTML::Template::Container::Section',
    'HEADER'      => 'PDF::FromHTML::Template::Container::Header',
    'FOOTER'      => 'PDF::FromHTML::Template::Container::Footer',

    'BOOKMARK'    => 'PDF::FromHTML::Template::Element::Bookmark',
    'CIRCLE'      => 'PDF::FromHTML::Template::Element::Circle',
    'HR'          => 'PDF::FromHTML::Template::Element::HorizontalRule',
    'IMAGE'       => 'PDF::FromHTML::Template::Element::Image',
    'PAGEBREAK'   => 'PDF::FromHTML::Template::Element::PageBreak',
    'LINE'        => 'PDF::FromHTML::Template::Element::Line',
    'TEXTBOX'     => 'PDF::FromHTML::Template::Element::TextBox',
    'VAR'         => 'PDF::FromHTML::Template::Element::Var',
    'WEBLINK'     => 'PDF::FromHTML::Template::Element::Weblink',

# These are the helper objects

    'TEXTOBJECT' => 'PDF::FromHTML::Template::TextObject',
    'CONTEXT'    => 'PDF::FromHTML::Template::Context',
    'ITERATOR'   => 'PDF::FromHTML::Template::Iterator',

    'MARGIN'     => 'PDF::FromHTML::Template::Container::Margin',

    'CONTAINER'  => 'PDF::FromHTML::Template::Container',
    'ELEMENT'    => 'PDF::FromHTML::Template::Element',

    'BASE'       => 'PDF::FromHTML::Template::Base',
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
