#=============================================================================
#
#       Copyright (c) 2010 Ars Aperta, Itaapy, Pierlis, Talend.
#       Copyright (c) 2014 Jean-Marie Gouarné.
#       Author: Jean-Marie Gouarné <jean.marie.gouarne@online.fr>
#
#=============================================================================
use     5.010_001;
use     strict;
use     experimental    'smartmatch';
#=============================================================================
#       The ODF Document class definition
#=============================================================================
package ODF::lpOD::Document;
our     $VERSION    = '1.013';
use     constant PACKAGE_DATE => '2014-04-30T08:27:07';
use     ODF::lpOD::Common;
#-----------------------------------------------------------------------------

BEGIN   {
        *forget                 = *DESTROY;
        *container              = *get_container;
        *body                   = *get_body;
        *add_part               = *add_file;
        *register_style         = *insert_style;
        }

#--- specific constructors ---------------------------------------------------

sub     get_from_uri
        {
        my $resource    = shift;
        unless ($resource)
                {
                alert "Missing source"; return FALSE;
                }
        return ODF::lpOD::Document->new(@_, uri => $resource);
        }

sub     create_from_template
        {
        my $resource    = shift;
        unless ($resource)
                {
                alert "Missing template"; return FALSE;
                }

        return ODF::lpOD::Document->new(@_, template => $resource);
        }

sub     get
        {
        my $caller      = shift;
        return ODF::lpOD::Document->new(uri => shift, @_);
        }

sub	    create
        {
        my $caller      = shift;
        return ODF::lpOD::Document->new(type => shift, @_);
        }

sub     _create
        {
        my $type        = shift;
        unless ($type)
                {
                alert "Missing document type"; return FALSE;
                }
        return ODF::lpOD::Document->new(@_, type => $type);
        }

#--- generic constructor & destructor ----------------------------------------

sub     new
        {
        my $class       = shift;
        my $self        = { @_ };
        bless $self, $class;
        $self->{uri} //= $self->{source}; delete $self->{source};
        if ($self->{type})      # new document, type provided
                {
                my $template = ODF::lpOD::Common::template($self->{type})
                                or return undef;
                $self->{container} = ODF::lpOD::Container->new
                                (template => $template) or return undef;
                my $meta = $self->get_part(META);
                if ($meta)
                        {
                        my $d = iso_date;
                        $meta->set_creation_date($d);
                        $meta->set_modification_date($d);
                        $meta->set_editing_duration('PT00H00M00S');
                        $meta->set_generator("ODF::lpOD $ODF::lpOD::VERSION");
                        $meta->set_initial_creator();
                        $meta->set_creator();
                        $meta->set_editing_cycles(1);
                        }
                }
        elsif ($self->{template})
                {
                $self->{container} = ODF::lpOD::Container->new
                                (template => $self->{template})
                                        or return undef;
                }
        elsif ($self->{uri})    # existing document, path provided
                {
                $self->{container} = ODF::lpOD::Container->new
                                (uri => $self->{uri}) or return undef;
                }
        $self->{pretty} //= ($self->{indent} // lpod->debug);
        return $self;
        }

sub     DESTROY
        {
        my $self        = shift;
        foreach my $part_name ($self->loaded_xmlparts)
                {
                next unless $part_name && $self->{$part_name};
                $self->{$part_name}->forget;
                delete $self->{$part_name};
                }
        delete $self->{xmlparts};
        $self->{container} && $self->{container}->DESTROY;
        $self = {};
        }

#--- XML part detection ------------------------------------------------------

sub     is_xmlpart
        {
        my $name        = shift;
        return ODF::lpOD::XMLPart::class_of($name) ? TRUE : FALSE;
        }

#--- document part accessors -------------------------------------------------

sub     get_container
        {
        my $self        = shift;
        my %opt         = @_;
        my $container   = $self->{container};
        unless ($container || is_false($opt{warning}))
                {
                alert "No available container";
                }
        return $container;
        }

sub     contains
        {
        my $self        = shift;
        my $container   = $self->get_container  or return undef;
        return $container->contains(@_);
        }

sub     parts
        {
        my $self        = shift;
        my $container   = $self->get_container  or return undef;
        return $container->parts;
        }

sub     get_stored_part
        {
        my $self        = shift;
        my $container   = $self->get_container  or return undef;
        return $container->get_stored_part(@_);
        }

sub     get_xmlpart
        {
        my $self        = shift;
        my $container   = $self->get_container(warning => TRUE)
                or return FALSE;

        my $part_name   = shift         or return FALSE;

        unless ($self->{$part_name})
                {
                my $xmlpart = ODF::lpOD::XMLPart->new
                                (
                                container       => $container,
                                part            => $part_name,
                                pretty          => $self->{pretty},
                                @_
                                );
                unless ($xmlpart)
                        {
                        alert "Unavailable part"; return FALSE;
                        }
                $self->{$part_name} = $xmlpart;
                $self->{$part_name}->{document} = $self;
                push @{$self->{xmlparts}}, $part_name;
                }
        return $self->{$part_name};
        }

sub     loaded_xmlparts
        {
        my $self        = shift;
        return undef unless $self->{xmlparts};
        return wantarray ? @{$self->{xmlparts}} : $self->{xmlparts};
        }

sub     get_body
        {
        my $self        = shift;
        return $self->content->get_body(@_);
        }

sub     get_part
        {
        my $self        = shift;
        my $container   = $self->get_container(warning => TRUE)
                                or return FALSE;
        my $part_name   = shift;
        if (is_xmlpart($part_name))
                {
                return $self->get_xmlpart($part_name, @_);
                }
        else
                {
                return $container->get_part($part_name, @_);
                }
        }

sub     content
        {
        my $self        = shift;
        return $self->get_xmlpart(CONTENT, @_);
        }

sub     meta
        {
        my $self        = shift;
        return $self->get_xmlpart(META, @_);
        }

sub     styles
        {
        my $self        = shift;
        return $self->get_xmlpart(STYLES, @_);
        }

sub     manifest
        {
        my $self        = shift;
        return $self->get_xmlpart(MANIFEST, @_);
        }

sub     get_parts
        {
        my $self        = shift;
        my $container   = $self->get_container(warning => TRUE)
                                or return FALSE;
        return $container->get_parts;
        }

sub     set_part
        {
        my $self        = shift;
        unless ($self->{container})
                {
                alert "No available container";
                return FALSE;
                }
        return $self->{container}->set_part(@_);
        }

sub     del_part
        {
        my $self        = shift;
        unless ($self->{container})
                {
                alert "No available container";
                return FALSE;
                }
        return $self->{container}->del_part(@_);
        }

sub     add_file
        {
        my $self        = shift;
        unless ($self->{container})
                {
                alert "No available container";
                return FALSE;
                }
        my $source      = shift;
        my %opt         = @_;
        my $path        = $opt{path} || $opt{part};
        delete @opt{qw(path part)};
        unless ($path)
                {
                if ($opt{type} && $opt{type} =~ /^image/)
                        {
                        my $filename = file_parse($source);
                        $path = 'Pictures/' . $filename;
                        }
                }
        $path = $self->{container}->add_file($source, $path, %opt);
        if ($path)
                {
                my $manifest = $self->get_part(MANIFEST);
                if ($manifest)
                        {
                        my $type = $opt{type} || file_type($source);
                        $manifest->set_entry($path, type => $type);
                        }
                }
        return $path;
        }

sub     add_image_file
        {
        my $self        = shift;
        my $source      = shift         or return undef;
        unless ($self->{container})
                {
                alert "No available ODF container";
                return FALSE;
                }
        my %opt         = @_;
        my ($filename, $sourcepath, $suffix) = file_parse($source);
        unless ($filename)
                {
                alert "No valid file name in $source";
                return FALSE;
                }
        my $type        = $opt{type} || file_type($source) || "image/$suffix";
        my $path        = 'Pictures/' . $filename;
        $suffix         //= 'unknown';

        my ($link, $size);
        if (wantarray)
                {
                my $buffer = load_file($source, ':raw');
                unless ($buffer)
                        {
                        alert "Resource $source not available";
                        return undef;
                        }
                $size = image_size(\$buffer);
                $link = $self->add_file
                        (
                        $buffer,
                        string          => TRUE,
                        path            => $path,
                        type            => $type,
                        @_
                        );
                return ($link, $size);
                }
        else
                {
                $link = $self->add_file
                        (
                        $source,
                        string          => FALSE,
                        path            => $path,
                        type            => $type,
                        @_
                        );
                return $link;
                }
        }

sub     get_mimetype
        {
        my $self        = shift;
        unless ($self->{mimetype})
                {
                $self->{mimetype} = $self->{container}->get_mimetype;
                }
        return $self->{mimetype};
        }

sub     set_mimetype
        {
        my $self        = shift;
        unless ($self->{container})
                {
                alert "No available container";
                return FALSE;
                }
        return $self->{container}->set_mimetype(shift);
        }

sub     get_type
        {
        my $self        = shift;
        my $mt = $self->get_mimetype    or return undef;
        $mt =~ s/.*opendocument\.//;
        return $mt;
        }

sub     save
        {
        my $self        = shift;
        my $container   = $self->get_container(warning => TRUE)
                                or return FALSE;
        my %opt         = @_;
        $opt{pretty} //= ($opt{indent} // lpod->debug);
        my $pretty = $opt{pretty};
        delete @opt{qw(pretty indent)};
        foreach my $part_name ($self->loaded_xmlparts)
                {
                next unless $part_name;
                my $part = $self->{$part_name}  or next;
                $part->store(pretty => $pretty) if is_true($part->{update});
                }
        return $container->save(%opt);
        }

#--- required insertion context retrieval ------------------------------------

sub     get_required_context
        {
        my $self        = shift;
        my $elt         = shift;
        my ($part_name, $path) = $elt->context_path;
        if ($part_name)
                {
                $path ||= '/';
                return $self->get_element($part_name, $path);
                }
        return undef;
        }

#--- context import & replacement --------------------------------------------

sub     substitute_context
        {
        my $self        = shift;
        my $doc         = shift;
        my $part        = shift;
        my $path        = shift;
        my $origin      = $doc->get_element($part, $path)
                                        or return undef;
        my $destination = $self->get_element($part, $path)
                                        or return undef;
        return $destination->substitute_children($origin);
        }

#--- direct element retrieval ------------------------------------------------

sub     get_element
        {
        my $self        = shift;
        my $part_name   = shift;
        my $part = $self->get_part($part_name);
        unless ($part)
                {
                alert "Unknown or not available document part";
                return undef;
                }
        return $part->get_element(@_);
        }

sub     get_elements
        {
        my $self	= shift;
        my $part_name   = shift;
        my $part = $self->get_part($part_name);
        unless ($part)
                {
                alert "Unknown or not available document part";
                return undef;
                }
        return $part->get_elements(@_);
        }

sub     get_headings
        {
        my $self        = shift;
        return $self->get_part(CONTENT)->get_headings(@_);
        }

sub     get_changes
        {
        my $self        = shift;
        my $part = $self->get_part(CONTENT)     or return undef;
        return $part->get_changes(@_);
        }

sub     get_change
        {
        my $self        = shift;
        my $part = $self->get_part(CONTENT)     or return undef;
        return $part->get_change(@_);
        }

#--- style handling ----------------------------------------------------------

sub     get_default_style
        {
        my $self        = shift;
        my $family      = shift;
        $family =~ s/ /-/g;
        my $xp =        '//style:default-style[@style:family="' .
                        $family . '"]';
        return $self->get_element(STYLES, $xp);
        }

sub     get_outline_style
        {
        my $self	= shift;
        my $xp          = '//text:outline-style';
        return $self->get_element(STYLES, $xp);
        }

sub     get_style
        {
        my $self        = shift;
        my $family      = shift;
        unless ($family)
                {
                alert "Missing style family"; return undef;
                }
        my $name        = shift;
        $family =~ s/ /-/g;
        unless ($name)
                {
                    if ($family eq 'outline')
                        {
                        return $self->get_outline_style;
                        }
                    else
                        {
                        return $self->get_default_style($family);
                        }
                }
        my $style; my $xp;
        my $f = $family; $f =~ s/[ _]/-/g;
        if ($family eq 'list')
                {
                $xp =   '//text:list-style[@style:name="'       .
                        $name . '"]';
                }
        elsif ($family =~ /(master|page-layout)/)
                {
                $xp =   '//style:' . $f . '[@style:name="'      .
                        $name . '"]';
                }
        elsif ($family eq 'data')
                {
                my $n = shift;
                $xp =   '//number:' . $name . '-style'        .
                        '[@style:name="' . $n . '"]';
                }
        elsif ($family eq 'gradient')
                {
                $xp =   '//draw:gradient[@draw:name="'  .
                        $name . '"]';
                }
        else
                {
                $xp =   '//style:style[@style:name="'   .
                        $name                           .
                        '"][@style:family="'            .
                        $f                              .
                        '"]';
                }
        return
                $self->get_element(STYLES, $xp)
                                //
                $self->get_element(CONTENT, $xp);
        }

sub     get_styles
        {
        my $self		= shift;
        my $family      = shift;
        unless ($family)
                {
                alert "Missing style family"; return undef;
                }
        if (ODF::lpOD::DataStyle->is_numeric_family($family))
                {
                return $self->get_data_styles($family, @_);
                }
        my $xp;
        my $f = $family; $f =~ s/[ _]/-/g;
        if ($family eq 'list')
                {
                $xp =   '//text:list-style';
                }
        elsif ($family eq 'master' || $family eq 'page layout')
                {
                $xp = '//style:' . $f;
                }
        elsif ($family eq 'gradient')
                {
                $xp = '//draw:gradient';
                }
        else
                {
                $xp = '//style:style[@style:family="' . $f . '"]';
                }

        return  (
                $self->get_elements(STYLES, $xp),
                $self->get_elements(CONTENT, $xp)
                );
        }

sub     get_data_styles
        {
        my $self	= shift;
        my $family      = shift;
        my $filter = $family ?
                'number:' . $family . '-style'  :
                qr'number:.*-style';
        my @ns = ();
        foreach my $part (STYLES, CONTENT)
                {
                my $r = $self->get_part($part)->get_root;
                push @ns, $_->get_descendants($filter)
                        for $r->get_elements(qr'office:(automatic-|)styles');
                }
        return @ns;
        }

sub     get_data_style
        {
        my $self        = shift;
        my ($family, $name) = @_;
        my $xp = "//number:$family-style";
        $xp .= '[@style:name="' . $name . '"]';
        return  $self->get_element(STYLES, $xp)
                //
                $self->get_element(CONTENT, $xp);
        }

sub     check_stylename
        {
        my $self        = shift;
        my $style       = shift;
        my $name        = shift || $style->get_name;
        my $family      = $style->get_family;
        unless ($name && $family)
                {
                alert "Missing style name and/or family";
                return FALSE;
                }
        if ($self->get_style($family, $name))
                {
                alert "Non unique style";
                return FALSE;
                }
        return TRUE;
        }

sub     select_style_context
        {
        my $self	= shift;
        my $style       = shift;
        my $context     = $self->get_required_context($style);
        return $context if $context;
        my %opt         = @_;
        my $xp;
        my $part_name = is_true($opt{default}) ? STYLES : $opt{part};
        if (is_true($opt{default}) || defined_false($opt{automatic}))
                {
                $part_name = STYLES; delete $opt{automatic};
                $xp = '//office:styles';
                }
        else
                {
                $part_name = $opt{part};
                if (is_true($opt{automatic}))
                        {
                        $xp = '//office:automatic-styles';
                        $part_name ||= CONTENT;
                        }
                else
                        {
                            if (!defined $part_name)
                                    {
                                    $part_name = STYLES;
                                    $xp = is_true($opt{automatic}) ?
                                            '//office:automatic-styles' :
                                            '//office:styles';
                                    }
                            elsif ($part_name eq STYLES)
                                    {
                                    $xp = is_true($opt{automatic}) ?
                                            '//office:automatic-styles' :
                                            '//office:styles';
                                    }
                            elsif ($part_name eq CONTENT)
                                    {
                                    $xp = '//office:automatic-styles';
                                    }
                        }
                }
        $context = $self->get_element($part_name, $xp);
        unless ($context)
                {
                alert "Wrong document structure; style insertion failure";
                return undef;
                }
        return $context;
        }

sub     insert_regular_style
        {
        my $self        = shift;
        my $style       = shift;
        my %opt         = @_;
        my $context     = $self->select_style_context($style, %opt)
                or return undef;
        if (is_true($opt{default}))
                {
                $style->check_tag('style:default-style');
                $style->set_name(undef);
                }
        else
                {
                my $name = $opt{name} || $style->get_name;
                return undef unless $self->check_stylename($style, $name);
                $style->check_tag($style->required_tag);
                $style->set_name($name);
                }
        return $context->insert_element($style);
        }

sub     insert_special_style
        {
        my $self        = shift;
        my $style       = shift;
        my %opt         = @_;
        my $context     = $self->select_style_context($style, %opt)
                or return undef;
        my $name = $opt{name} || $style->get_name;
        return undef unless $self->check_stylename($style, $name);
        $style->check_tag($style->required_tag);
        $style->set_name($name);
        return $context->insert_element($style);
        }

sub     insert_outline_style
        {
        my $self	= shift;
        my $style       = shift;
        my $context = $self->select_style_context($style) or return undef;
        my $old = $self->get_style('outline'); $old && $old->delete;
        $style->set_name(undef);
        $style->check_tag($style->required_tag);
        return $context->insert_element($style);
        }

sub     insert_default_style
        {
        my $self	= shift;
        my $style       = shift;
        my $context = $self->get_element(STYLES, '//office:styles');
        unless ($context)
                {
                alert "Default style context not available";
                return undef;
                }
        my $family = $style->get_family;
        my $ds = $style->make_default           or return FALSE;
        my $old = $self->get_style($family);
        $old->delete() if $old;
        return $context->insert_element($ds);
        }

sub     insert_style
        {
        my $self        = shift;
        my $style       = shift;
        my $class       = ref $style;
        if ($class)
                {
                if ($class eq 'ARRAY')
                        {
                        $style = ODF::lpOD::Style->create(@$style);
                        $class = ref $style;
                        }
                }
        unless ($class && $style->isa('ODF::lpOD::Style'))
                {
                alert "Missing or wrong style element";
                return FALSE;
                }
        my %opt         = @_;
        my $family      = $style->get_family;
        if (is_true($opt{default}))
                {
                return $self->insert_default_style($style, $family);
                }
        if ($family =~ /^(text|paragraph|graphic|gradient|drawing page|number|currency|date)$/)
                {
                return $self->insert_regular_style($style, %opt);
                }
        elsif ($family =~ /(list|master|page layout)/)
                {
                return $self->insert_special_style($style, %opt);
                }
        elsif ($family eq 'outline')
                {
                return $self->insert_outline_style($style);
                }
        elsif ($family =~ /^table/)
                {
                $opt{automatic} = TRUE unless exists $opt{automatic};
                $opt{part} = CONTENT unless $opt{part};
                return $self->insert_special_style($style, %opt);
                }
        else
                {
                alert "Not supported"; return undef;
                }
        }

#--- bulk style replacement by import from another document ------------------

sub     substitute_styles
        {
        my $self        = shift;
        my $from        = shift;
        my %opt         =
                (
                common          => TRUE,
                master          => TRUE,
                automatic       => TRUE,
                fonts           => TRUE,
                @_
                );
        my $source;
        if (ref $from)
                {
                $source = $from if $from->isa('ODF::lpOD::Document');
                }
        else
                {
                $source = ODF::lpOD::Document->new(template => $from);
                }
        unless ($source)
                {
                alert "Malformed or not available source"; return FALSE;
                }

        my $count = 0;
        foreach my $part ($self->get_part(CONTENT), $self->get_part(STYLES))
                {
                $count += $part->substitute_styles($source, %opt);
                }

        $source->forget unless ref $from;
        return $count;
        }

#--- document variable handling ----------------------------------------------

sub     get_user_variables
        {
        my $self        = shift;
        my %opt         = @_;
        my $context     = $opt{context} // $self->get_body;
        return $context->get_elements('text:user-field-decl');
        }

sub	get_simple_variables
        {
        my $self	= shift;
        my %opt         = @_;
        my $context     = $opt{context} // $self->get_body;
        return $context->get_elements('text:variable-decl');
        }

sub	get_variables
        {
        my $self	= shift;
        my %opt         = @_;
            if (!defined $opt{class})
                    {
                    return  (
                            $self->get_user_variables(@_),
                            $self->get_simple_variables(@_)
                            );
                    }
            elsif ($opt{class} eq 'user')
                    {
                    return $self->get_user_variables;
                    }
            elsif ($opt{class} eq 'simple')
                    {
                    return $self->get_simple_variables;
                    }
            else
                    {
                    alert "Unknown variable class $opt{class}";
                    return undef;
                    }
        }

sub     get_variable
        {
        my $self        = shift;
        my $name        = shift;
        my %opt         = ( class => 'user', @_ );
        my $context     = $opt{context} // $self->get_body;
        my $tag;
        if (!defined $opt{class})
                {
                return  $self->get_variable($name, class => 'user')
                                        ||
                        $self->get_variable($name, class => 'simple');
                }
        elsif ($opt{class} eq 'user')
                {
                $tag = 'text:user-field-decl';
                }
        elsif ($opt{class} eq 'simple')
                {
                $tag = 'text:variable-decl';
                }
        else
                {
                alert "Wrong variable class"; return undef;
                }

        return $context->get_element
                ($tag, attribute => 'name', value => $name);
        }

sub     set_variable
        {
        my $self        = shift;
        my $name        = shift;
        unless ($name)
                {
                alert "Missing variable name";          return FALSE;
                }
        if ($self->get_variable($name, class => undef))
                {
                alert "Variable $name already exists";  return FALSE;
                }
        my %opt         =
                (
                name    => $name,
                class   => 'user',
                type    => 'string',
                @_
                );

        my $class = $opt{class};
        my $context = $opt{context};
        delete @opt{qw(class context)};
        my $var;
        if ($class eq 'user')
                {
                $var = ODF::lpOD::UserVariable->create(%opt);
                }
        elsif ($class eq 'simple')
                {
                $var = ODF::lpOD::SimpleVariable->create(%opt);
                }
        else
                {
                alert "Unsupported variable class";
                }
        if ($var)
                {
                my $tag = $var->context_tag;
                $context //= $self->get_body->set_first_child($tag);
                if ($context)
                        {
                        $context->append_element($var);
                        }
                else
                        {
                        alert "Unknown object insertion context";
                        $var->delete; $var = undef;
                        }
                }
        return $var;
        }

#--- table of content handling -----------------------------------------------

sub     get_tocs
        {
        my $self	= shift;
            return $self->get_part(CONTENT)->get_tocs(@_);
        }

sub     get_toc
        {
        my $self        = shift;
        return $self->get_part(CONTENT)->get_toc(@_);
        }

#--- named range handling ----------------------------------------------------

sub     get_named_range
        {
        my $self        = shift;
        return $self->get_part(CONTENT)->get_named_range(@_);
        }

sub     set_named_range
        {
        my $self        = shift;
        return $self->get_part(CONTENT)->set_named_range(@_);
        }

#--- font declaration --------------------------------------------------------

sub     set_font_declaration
        {
        my $self	= shift;
        return  (
                $self->get_part(CONTENT)->set_font_declaration(@_),
                $self->get_part(STYLES)->set_font_declaration(@_)
                );
        }

#=============================================================================
package ODF::lpOD::Container;
our	$VERSION	= '1.004';
use constant PACKAGE_DATE => '2012-02-19T19:08:31';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------
use Archive::Zip        1.30    qw ( :DEFAULT :CONSTANTS :ERROR_CODES );
#=============================================================================

BEGIN   {
        *forget                 = *DESTROY;
        *get_parts              = *parts;
        *add_part               = *add_file;
        }

#=== parameters ==============================================================

our %ODF_PARTS  =
        (
        content         => CONTENT,
        styles          => STYLES,
        meta            => META,
        manifest        => MANIFEST,
        settings        => SETTINGS,
        mimetype        => MIMETYPE
        );

our %PARTS_ODF  = reverse %ODF_PARTS;

sub     translate_part_name
        {
        my $name        = shift         or return undef;
        return $ODF_PARTS{$name} ? $ODF_PARTS{$name} : $name;
        }

our     %COMPRESSION    =               # compression rule for some parts
        (
        MIMETYPE        => FALSE,
        META            => FALSE,
        CONTENT         => TRUE,
        STYLES          => TRUE,
        MANIFEST        => TRUE,
        SETTINGS        => TRUE
        );

#=============================================================================

sub     get_from_uri
        {
        return ODF::lpOD::Container->new(uri => shift);
        }

#-----------------------------------------------------------------------------

sub     create_from_template
        {
        return ODF::lpOD::Container->new(template => shift);
        }

#-----------------------------------------------------------------------------

sub     create
        {
        return ODF::lpOD::Container->new(type => shift);
        }

#=============================================================================

sub     new
        {
        my $class       = shift;
        my $self        =
                {
                type            => undef,
                uri             => undef,
                read_only       => undef,
                zip             => undef,
                deleted         => [],
                stored          => {},
                @_
                };

        if ($self->{type})
                {
                $self->{uri} = ODF::lpOD::Common::template($self->{type})
                                or return undef;
                $self->{read_only}      = TRUE;
                $self->{create}         = TRUE;
                }
        elsif ($self->{template})
                {
                $self->{uri}            = $self->{template};
                $self->{read_only}      = TRUE;
                $self->{create}         = FALSE;
                }
        else
                {
                $self->{create}         = FALSE;
                }

        my $source = $self->{uri};
        my $zip = defined $self->{zip} ?
                $self->{zip} : Archive::Zip->new;

        if (UNIVERSAL::isa($source, 'IO::File'))
                {
                if ($zip->readFromFileHandle($source) != AZ_OK)
                        {
                        alert("Handle read error");
                        return FALSE;
                        }
                }
        else
                {
                unless	(-r -f -e $source)
                    {
                    alert("Missing source");
                    return FALSE;
                    }
                if ($zip->read($source) != AZ_OK)
                    {
                    alert("File read error");
                    return FALSE;
                    }
                }

        $self->{zip} = $zip;
        bless $self, $class;
        return $self;
        }

#-----------------------------------------------------------------------------

sub     DESTROY
        {
        my $self        = shift;
        undef $self->{zip};
        $self = {};
        }

#-----------------------------------------------------------------------------

sub     get_mimetype
        {
        my $self        = shift;
        return $self->get_part(MIMETYPE);
        }

sub     set_mimetype
        {
        my $self        = shift;
        return $self->set_part(
                MIMETYPE, shift, compress => FALSE, string => TRUE
                );
        }

#-----------------------------------------------------------------------------

sub     parts
        {
        my $self        = shift;
        return $self->{zip}->memberNames;
        }

#-----------------------------------------------------------------------------

sub     contains
        {
        my $self        = shift;
        my $part_name   = shift         or return FALSE;
        return (grep $_ eq $part_name, $self->parts) ? TRUE : FALSE;
        }

#-----------------------------------------------------------------------------

sub     raw_set_part
        {
        my $self        = shift;
        my $part_name   = shift;

        my $data        = shift;
        my %opt         =
                (
                string                  => TRUE,
                compress                => undef,
                compression_method      => COMPRESSION_DEFLATED,
                compression_level       => COMPRESSION_LEVEL_BEST_COMPRESSION,
                @_
                );

        my $compress = $opt{compress} // $COMPRESSION{$part_name} // FALSE;
        my $zip = $self->{zip};
        my $buffer = is_true($opt{string}) ? $data : load_file($data, ':raw');
        my $p = $zip->addString($buffer, $part_name);

        if ($p)
                {
                if (is_true($compress))
                        {
                        $p->desiredCompressionMethod($opt{compression_method});
                        $p->desiredCompressionLevel($opt{compression_level});
                        }
                else
                        {
                        $p->desiredCompressionMethod(COMPRESSION_STORED);
                        }
                return TRUE;
                }
        else
                {
                alert("Data storage error");
                return FALSE;
                }
        }

#-----------------------------------------------------------------------------

sub     raw_del_part
        {
        my $self        = shift;
        my $part_name   = shift;
        return FALSE unless $self->contains($part_name);

        my $status      = $self->{zip}->removeMember($part_name);
        unless ($status)
                {
                alert("$part_name removal failed");
                return FALSE;
                }
        return TRUE;
        }

#=============================================================================

sub     set_part
        {
        my $self        = shift;
        my $part_name   = translate_part_name(shift)    or return FALSE;
        my $data        = shift // "";
        my %opt         =
                (
                string          => FALSE,
                compress        => FALSE,
                @_
                );

        $self->{stored}{$part_name}{data}       = $data;
        $self->{stored}{$part_name}{string}     = $opt{string};
        $self->{stored}{$part_name}{compress}   = $opt{compress};

        $self->del_part($part_name);

        return $part_name;
        }

#-----------------------------------------------------------------------------

sub     add_file
        {
        my $self        = shift;
        my $path        = shift         or return undef;
        my $destination = shift;
        my %opt         =
                (
                string          => FALSE,
                @_
                );
        unless ($destination)
                {
                my $mimetype = file_type($path);
                my $filename = file_parse($path);
                if ($mimetype && $mimetype =~ /^image/)
                        {
                        $destination = 'Pictures/' . $filename;
                        $opt{compress} = FALSE;
                        }
                else
                        {
                        $destination = $filename;
                        $opt{compress} = TRUE;
                        }
                }
        return $self->set_part($destination, $path, %opt);
        }

#-----------------------------------------------------------------------------

sub     get_stored_part
        {
        my $self        = shift;
        my $part_name   = shift;
        return $self->{stored}{$part_name};
        }

sub     get_part
        {
        my $self        = shift;
        my $part_name   = translate_part_name(shift);
        unless ($part_name)
                {
                alert "Missing part name";
                return FALSE
                }
        unless ($self->contains($part_name))
                {
                alert("Unknown part $part_name");
                return FALSE;
                }
        my ($result, $status) =  $self->{'zip'}->contents($part_name);
        return $status == AZ_OK ? $result : undef;
        }

#-----------------------------------------------------------------------------

sub     del_part
        {
        my $self        = shift;
        my $part_name   = translate_part_name(shift)    or return FALSE;
        push @{$self->{deleted}}, $part_name;
        return TRUE;
        }

#-----------------------------------------------------------------------------

sub     save
        {
        my $self        = shift;
        my %opt         =
                        (
                        target          => undef,
                        packaging       => 'zip',
                        @_
                        );
        if (is_true($self->{read_only}))
                {
                unless  (
                            (defined $opt{target})          &&
                            $opt{target} ne $self->{uri}
                        )
                        {
                        alert("Read-only container");
                        return undef;
                        }
                }
        my $target      = $opt{target};
        my $packaging   = $opt{packaging};

        $self->raw_del_part($_) for @{$self->{deleted}};

        foreach my $part_name (keys %{$self->{stored}})
                {
                my $data        = $self->{stored}{$part_name}{data};
                my $compress    = $self->{stored}{$part_name}{compress};
                my $string      = $self->{stored}{$part_name}{string};
                $self->raw_del_part($part_name);
                $self->raw_set_part
                        (
                        $part_name, $data,
                        compress        => $compress,
                        string          => $string
                        );
                }

        my $status = undef;
        unless (defined $target)
                {
                $status = $self->{zip}->overwrite();
                }
        elsif (UNIVERSAL::isa($target, 'IO::File'))
                {
                $status = $self->{zip}->writeToFileHandle($target);
                }
        else
                {
                $status = $self->{zip}->writeToFileNamed($target);
                }

        unless ($status == AZ_OK)
                {
                alert("Zip I/O error");
                return FALSE;
                }

        $self->{deleted} = [];
        $self->{stored} = {};
        return TRUE;
        }

#=============================================================================
package ODF::lpOD::XMLPart;
our     $VERSION    = '1.007';
use constant PACKAGE_DATE => '2012-05-15T08:36:28';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

BEGIN   {
        *forget                 = *DESTROY;
        *body                   = *get_body;
        *get_container          = *container;
        *get_document           = *document;
        *root                   = *get_root;
        *get_element_list       = *get_elements;
        *export                 = *serialize;
        }

sub     class_of
        {
        my $part        = shift;
        return ref $part if ref $part;
        if    ($part eq CONTENT)          { return 'ODF::lpOD::Content'   }
        elsif ($part eq STYLES)           { return 'ODF::lpOD::Styles'    }
        elsif ($part eq META)             { return 'ODF::lpOD::Meta'      }
        elsif ($part eq SETTINGS)         { return 'ODF::lpOD::Settings'  }
        elsif ($part eq MANIFEST)         { return 'ODF::lpOD::Manifest'  }
        else  { return undef }
        }

our %CLASS      =
        (
        content         => 'ODF::lpOD::Content',
        styles          => 'ODF::lpOD::Styles',
        meta            => 'ODF::lpOD::Meta',
        manifest        => 'ODF::lpOD::Manifest',
        settings        => 'ODF::lpOD::Settings'
        );

sub     pre_load        {}
sub     post_load
        {
        my $self        = shift;
        $self->get_root->set_classes;
        }

#=== exported part ===========================================================

sub     get
        {
        my $container   = shift;
        unless (ref $container && $container->isa('ODF::lpOD::Container'))
                {
                alert "Missing or not valid container";
                return FALSE;
                }
        my $part_name   = shift;
        unless (class_of($part_name))
                {
                alert "Missing or unknown document part";
                return FALSE;
                }
        return ODF::lpOD::XMLPart->new
                (
                part            => $part_name,
                container       => $container,
                @_
                );
        }

#=============================================================================
#--- constructor and associated utilities ------------------------------------

sub     new
        {
        my $class       = shift;
        my $self        =
                {
                container       => undef,
                part            => undef,
                load            => TRUE,
                elt_class       => 'ODF::lpOD::Element',
                twig            => undef,
                context         => undef,
                @_
                };

        unless (defined $self->{update})
                {
                $self->{update} = $self->{roots} ? FALSE : TRUE;
                }
        my $part_class = class_of($self->{part});
        unless ($class)
                {
                alert "Unknown ODF XML part"; return FALSE;
                }
        $self->{pretty} //= ($self->{indent} // lpod->debug);
        $self->{pretty_print} = PRETTY_PRINT if is_true($self->{pretty});
        $self->{twig} //= XML::Twig->new        # twig init
                                (
                                twig_handlers   => $self->{handlers},
                                twig_roots      => $self->{roots},
                                elt_class       => $self->{elt_class},
                                pretty_print    => $self->{pretty_print},
                                output_encoding => TRUE,
                                id              => $ODF::lpOD::Common::LPOD_ID
                                );
        $self->{twig}->set_output_encoding('UTF-8');

        bless $self, $part_class;
        if ($self->{load})
                {
                my $status = $self->load();
                unless (is_true($status))
                        {
                        alert("Part load failed");
                        return FALSE;
                        }
                }
        return $self;
        }

sub     load
        {
        my $self        = shift;
        my $xml         = shift || $self->{container}->get_part($self->{part});

        unless (defined $xml)
                {
                alert("No content");
                return FALSE;
                }

        $self->pre_load;
        my $r = UNIVERSAL::isa($xml, 'IO::File') ?
                $self->{twig}->safe_parsefile($xml)     :
                $self->{twig}->safe_parse($xml);
        unless ($r)
                {
                alert "No valid XML content";
                return FALSE;
                }
        $self->{context} = $self->{twig}->root;
        $self->{context}->lpod_part($self);
        $self->post_load;
        return TRUE;
        }

sub	    needs_update
        {
        my $self	= shift;
        my $arg         = shift;
            if (!defined $arg)    {}
            elsif ($arg == TRUE)  { $self->{update} = TRUE  }
            elsif ($arg == FALSE) { $self->{update} = FALSE }
            return $self->{update};
        }
    
sub	    get_name
        {
        my $self	= shift;
        return $self->{part};
        }

#--- destructor --------------------------------------------------------------

sub     DESTROY
        {
        my $self        = shift;
        $self->{context} &&
                $self->{context}->del_att($ODF::lpOD::Common::LPOD_PART);
        $self->{context} && $self->{context}->delete;
        delete $self->{context};
        $self->{twig} && $self->{twig}->dispose;
        delete $self->{twig};
        delete $self->{container};
        delete $self->{part};
        $self = {};
        }

#--- basic individual node selection -----------------------------------------

sub     find_node
        {
        my $self        = shift;
        my $tag         = shift;
        my $context     = shift || $self->{context};

        return $context->first_descendant($tag);
        }

#=== public part =============================================================
#--- general document management ---------------------------------------------

sub     get_class
        {
        my $self        = shift;
        return ref $self;
        }

sub     get_root
        {
        my $self        = shift;
        return $self->{twig}->root;
        }

sub     get_body
        {
        my $self        = shift;
        my $tag         = shift;
        my $root = $self->get_root;
        if ($tag)
                {
                $tag = 'office:' . $tag unless $tag =~ /:/;
                return $root->get_xpath(('//office:body/' . $tag), 0);
                }
        my $context = $root->get_xpath('//office:body', 0);
        return $context ?
                $context->first_child
                    (qr'office:(text|spreadsheet|presentation|drawing)')
                        :
                $root->first_child
                    (qr'office:(body|meta|master-styles|settings)');
        }

sub     container
        {
        my $self        = shift;
        return $self->{container};
        }

sub     document
        {
        my $self        = shift;
        return $self->{document};
        }

sub     serialize
        {
        my $self        = shift;
        my %opt         =
                (
                empty_tags      => EMPTY_TAGS,
                output          => undef,
                @_
                );
        $opt{pretty} //= ($self->{indent} // lpod->debug);
        $opt{pretty_print} = PRETTY_PRINT if is_true($opt{pretty});
        my $output = $opt{output};
        delete @opt{qw(pretty output indent)};
        return (defined $output) ?
                $self->{twig}->print($output, %opt)   :
                $self->{twig}->sprint(%opt);
        }

sub     store
        {
        my $self        = shift;
        unless ($self->{container})
                {
                alert "No associated container";
                return FALSE;
                }
        my %opt         = @_;
        my %storage     = ();
        if ($opt{storage})
                {
                %storage = %{$opt{storage}};
                delete $opt{storage};
                }
        else
                {
                %storage = (compress => TRUE, string => TRUE);
                }
        return
                $self->{container}->set_part
                        (
                        $self->{part},
                        $self->serialize(%opt),
                        %storage
                        );
        }

#--- general element management ----------------------------------------------

sub     get_elements
        {
        my ($self, $xpath) = @_;
        return $self->{context}->get_xpath($xpath);
        }

sub     get_element
        {
        my $self        = shift;
        my $xpath       = shift;
        my $offset      = shift || 0;
        return $self->{context}->get_xpath($xpath, $offset);
        }

sub     append_element
        {
        my $self        = shift;
        my $context     = $self->get_root;
        return $context->append_element(@_);
        }

sub     insert_element
        {
        my $self        = shift;
        my $context     = $self->get_root;
        return $context->insert_element(@_);
        }

sub     delete_element
        {
        my ($self, $element) = @_;
        return $element->delete;
        }

#--- tracked change handling -------------------------------------------------

sub     get_tracked_changes_root
        {
        my $self        = shift;
        unless ($self->{tracked_changes})
                {
                $self->{tracked_changes} =
                        $self->find_node('text:tracked-changes');
                }
        return $self->{tracked_changes};
        }

sub     get_changes
        {
        my $self        = shift;
        my $context     = $self->get_tracked_changes_root;
        unless ($context)
                {
                alert "Not valid tracked change retrieval context";
                return FALSE;
                }
        return $context->get_changes(@_);
        }

sub     get_change
        {
        my $self        = shift;
        my $context     = $self->get_tracked_changes_root;
        unless ($context)
                {
                alert "Not valid tracked change retrieval context";
                return FALSE;
                }
        return $context->get_change(shift);
        }

#=============================================================================
package ODF::lpOD::StyleContainer;
use base 'ODF::lpOD::XMLPart';
our $VERSION    = '1.001';
use constant PACKAGE_DATE => '2011-05-29T16:05:40';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     get_font_declarations
        {
        my $self	= shift;
        return $self->get_elements
                ('//office:font-face-decls/style:font-face');
        }

sub     get_font_declaration
        {
        my $self	= shift;
        my $name        = shift         or return undef;
        my $xp =        '//office:font-face-decls'              .
                        '/style:font-face[@style:name="'        .
                        $name                                   .
                        '"]';
        return $self->get_element($xp);
        }

sub     set_font_declaration
        {
        my $self	= shift;
        my $name        = shift;
        unless ($name)
                {
                alert "Missing font name"; return undef;
                }
        my %opt         = process_options(@_);
        $opt{family}    ||= $name;
        my $fd = $self->get_font_declaration($name);
        $fd->delete if $fd;
        return $self
                ->get_root
                ->set_child('office:font-face-decls')
                ->append_element
                        (ODF::lpOD::FontDeclaration->create($name, %opt));
        }

sub     substitute_context
        {
        my $self	= shift;
        my $doc         = shift;
        my $path        = shift;

        my $part        = $self->get_name;
        my $origin      = $doc->get_element($part, $path)
                                        or return undef;
        my $destination = $self->get_element($path)
                                        or return undef;
        return $destination->substitute_children($origin);
        }

sub	substitute_styles
        {
        my $self	= shift;
        my $from        = shift;

        my %opt         =
                (
                common          => TRUE,
                master          => TRUE,
                automatic       => TRUE,
                fonts           => TRUE,
                @_
                );
        my $part = $self->get_name;
        if ($part ne STYLES)
                {
                delete @opt{qw(common master)};
                }
        my $source;
        if (ref $from)
                {
                $source = $from if $from->isa('ODF::lpOD::Document');
                }
        else
                {
                $source = ODF::lpOD::Document->new(template => $from);
                }
        unless ($source)
                {
                alert "Malformed or not available source"; return FALSE;
                }

        my $count = 0;

        if (is_true($opt{automatic}))
                {
                $count += $self->substitute_context
                        ($source, '//office:automatic-styles');
                }
        if (is_true($opt{common}))
                {
                $count += $self->substitute_context
                        ($source, '//office:styles');
                }
        if (is_true($opt{master}))
                {
                $count += $self->substitute_context
                        ($source, '//office:master-styles');
                }
        if (is_true($opt{fonts}))
                {
                $count += $self->substitute_context
                        ($source, '//office:font-face-decls');
                }

        $source->forget unless ref $from;
        return $count;
        }

#=============================================================================
package ODF::lpOD::Content;
use base 'ODF::lpOD::StyleContainer';
our $VERSION    = '1.003';
use constant PACKAGE_DATE => '2012-03-29T08:25:40';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     get_tocs
        {
        my $self	= shift;
        my $context     = $self->get_body;
            return $context->get_elements('text:table-of-content');
        }

sub     get_toc
        {
        my $self        = shift;
        my $name        = shift;
        my $context = $self->get_body;
        return $context->get_element_by_name('text:table-of-content', $name);
        }

sub     get_named_range
        {
        my $self        = shift;
        my $context = $self->get_body('spreadsheet');
        unless ($context)
                {
                alert "Not in spreadsheet context"; return undef;
                }
        return $context->get_element_by_name('table:named-range', @_);
        }

sub     set_named_range
        {
        my $self        = shift;
        my $body = $self->get_body('spreadsheet');
        unless ($body)
                {
                alert "Not in spreadsheet context"; return undef;
                }
        my $name        = shift;
        my $old = $self->get_named_range($name);
        if ($old)
                {
                alert "Named range $name already exists"; return undef;
                }
        my $context = $body->set_last_child('table:named-expressions');
        my $nr = ODF::lpOD::NamedRange->create($name, @_);
        $context->append_element($nr);
        return $nr;
        }

sub     get_headings
        {
        my $self        = shift;
        return $self->get_body->get_headings(@_);
        }

#=============================================================================
package ODF::lpOD::Styles;
use base 'ODF::lpOD::StyleContainer';
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2010-12-24T13:51:47';
use ODF::lpOD::Common;
#=============================================================================
package ODF::lpOD::Meta;
use base 'ODF::lpOD::XMLPart';
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2010-12-24T13:51:58';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

BEGIN   {
        *get_element_list       = *get_elements;
        }

sub     post_load       {}

#-----------------------------------------------------------------------------

our %META =
        (
        creation_date           => 'meta:creation-date',
        creator                 => 'dc:creator',
        description             => 'dc:description',
        editing_cycles          => 'meta:editing-cycles',
        editing_duration        => 'meta:editing-duration',
        generator               => 'meta:generator',
        initial_creator         => 'meta:initial-creator',
        language                => 'dc:language',
        modification_date       => 'dc:date',
        printed_by              => 'meta:printed-by',
        print_date              => 'meta:print-date',
        subject                 => 'dc:subject',
        title                   => 'dc:title'
        );

#-----------------------------------------------------------------------------

sub     get_body
        {
        my $self        = shift;
        unless ($self->{body})
                {
                $self->{body} = $self->SUPER::get_element('//office:meta');
                }
        return $self->{body};
        }

sub     get_element
        {
        my $self        = shift;
        return $self->get_body->get_element(@_);
        }

sub     get_elements
        {
        my $self        = shift;
        return $self->get_body->get_element_list(@_);
        }

sub     append_element
        {
        my $self        = shift;
        return $self->get_body->append_element(@_);
        }

#-----------------------------------------------------------------------------

sub     get_statistics
        {
        my $self        = shift;
        my $stat        = $self->get_element('meta:document-statistic');
        return $stat ? $stat->get_attributes() : undef;
        }

sub     set_statistics
        {
        my $self        = shift;
        my $stat =      $self->get_element('meta:document-statistic') ||
                        $self->append_element('meta:document-statistic');
        return $stat->set_attributes(@_);
        }

#-----------------------------------------------------------------------------

sub     get_keyword_list
        {
        my $self        = shift;
        my $expr        = shift;
        return $self->get_element_list
                        ('meta:keyword', content => $expr);
        }

sub     get_keywords
        {
        my $self        = shift;
        my @kwl         = ();
        for ($self->get_keyword_list(@_))
                {
                push @kwl, $_->get_text;
                }
        return wantarray ? @kwl : join (', ', @kwl);
        }

sub     set_keyword
        {
        my $self        = shift;
        my $kw          = shift // return undef;
        for ($self->get_keyword_list)
                {
                return FALSE if $_->get_text() eq $kw;
                }
        my $e = $self->append_element('meta:keyword');
        $e->set_text($kw);
        return $e;
        }

sub     set_keywords
        {
        my $self        = shift;
        my $input       = join(',', @_);
        foreach my $kw (split(',', $input))
                {
                $kw =~ s/^ *//; $kw =~ s/ *$//;
                $self->set_keyword($kw);
                }
        return $self->get_keywords;
        }

sub     check_keyword
        {
        my $self        = shift;
        my $expr        = shift         or return undef;

        return scalar $self->get_keyword_list($expr);
        }

sub     remove_keyword
        {
        my $self        = shift;
        my $expr        = shift         or return undef;
        my $count       = 0;
        for ($self->get_keyword_list($expr))
                {
                $_->delete; $count++;
                }
        return $count;
        }

#-----------------------------------------------------------------------------

sub     get_user_field
        {
        my $self        = shift;
        my $name        = shift         or return undef;
        my $e = ref $name ?
                        $name
                                :
                        $self->get_element
                                (
                                'meta:user-defined',
                                attribute       => 'name',
                                value           => $name
                                );
        return undef unless $e;
        return wantarray ?
                (
                        $e->get_text(),
                        $e->get_attribute('value type') || 'string'
                )
                :
                $e->get_text;
        }

sub     set_user_field
        {
        my $self        = shift;
        my $name        = shift;
        my $value       = shift;
        my $type        = shift || 'string';
        unless (is_odf_datatype($type))
                {
                alert "Wrong data type $type";
                return FALSE;
                }
        unless ($name)
                {
                alert "Missing user field name";
                return FALSE;
                }
        $value = check_odf_value($value, $type);
        my $e = $self->get_element
                        (
                        'meta:user-defined',
                        attribute       => 'name',
                        value           => $name
                        )
                        //
                $self->append_element('meta:user-defined');
        $e->set_attribute('name' => $name);
        $e->set_attribute('value type' => $type);
        $e->set_text($value);
        return wantarray ?
                ($e->get_text(), $e->get_attribute('value type'))
                        :
                $e->get_text;
        }

sub     get_user_fields
        {
        my $self        = shift;
        my @result      = ();
        foreach my $e ($self->get_element_list('meta:user-defined'))
                {
                my $f;
                $f->{name}      = $e->get_attribute('name');
                $f->{type}      = $e->get_attribute('value type') // 'string';
                $f->{value}     = $e->get_text() // "";
                push @result, $f;
                }
        return @result;
        }

sub     set_user_fields
        {
        my $self	= shift;
        foreach my $f (@_)
                {
                $self->set_user_field($f->{name}, $f->{value}, $f->{type});
                }
        return $self->get_user_fields;
        }

#-----------------------------------------------------------------------------

our     $AUTOLOAD;
sub     AUTOLOAD
        {
        my $self        = shift;
        $AUTOLOAD       =~ /.*:(.*)/;
        my $method      = $1;
        $method =~ /^([gs]et)_(.*)/;
        my $action      = $1;
        my $object      = $META{$2};

        unless ($action && $object)
                {
                alert "Unsupported method $method";
                return undef;
                }

        my $e = $self->get_element($object);
        if (!defined $action)
                {
                alert "Unsupported action";
                }
        elsif ($action eq 'get')
                {
                return $e ? $e->get_text() : undef;
                }
        elsif ($action eq 'set')
                {
                unless ($e)
                        {
                        my $body = $self->get_body;
                        $e = $body->append_element($object);
                        }
                my $v = shift;
                if ($object =~ /date$/)
                        {
                        unless ($v)
                                {
                                $v = iso_date;
                                }
                        else
                                {
                                $v = check_odf_value($v, 'date');
                                }
                        }
                elsif ($object =~ /creator$/)
                        {
                        $v      =
                                $v =    (scalar getlogin())     ||
                                        (scalar getpwuid($<))   ||
                                        $<
                                unless $v;
                        }
                elsif ($object =~ /generator$/)
                        {
                        $v = $0 || $$   unless $v;
                        }
                elsif ($object =~ /cycles$/)
                        {
                        unless ($v)
                                {
                                $v = $e->get_text() || 0;
                                $v++;
                                }
                        }
                return $e->set_text($v);
                }
        return undef;
        }

#-----------------------------------------------------------------------------

sub     store
        {
        my $self        = shift;
        my %opt         =
                (
                storage     => { compress => FALSE, string => TRUE },
                @_
                );
        return $self->SUPER::store(%opt);
        }

#=============================================================================
package ODF::lpOD::Settings;
use base 'ODF::lpOD::XMLPart';
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2010-12-24T13:52:14';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     post_load       {}

#=============================================================================
package ODF::lpOD::Manifest;
use base 'ODF::lpOD::XMLPart';
our $VERSION    = '1.001';
use constant PACKAGE_DATE => '2010-12-30T08:34:26';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     post_load       {}

#-----------------------------------------------------------------------------

sub     get_entries
        {
        my $self        = shift;
        my %opt         = @_;
        my @all_entries = $self->{context}->get_element_list
                                                ('manifest:file-entry');
        unless (defined $opt{type})
                {
                return @all_entries;
                }
        my @selected_entries = ();
        ENTRY: foreach my $e (@all_entries)
                {
                my $type = $e->get_attribute('media type');
                next ENTRY unless defined $type;
                if ($opt{type} eq "")
                        {
                        push @selected_entries, $e      if $type eq "";
                        next ENTRY;
                        }
                push @selected_entries, $e      if $type =~ /$opt{type}/;
                }
        return @selected_entries;
        }

sub     get_entry
        {
        my $self        = shift;
        return $self->{context}->get_element(
                        'manifest:file-entry',
                        attribute       => 'full path',
                        value           => shift
                        );
        }

sub     set_entry
        {
        my $self        = shift;
        my $path        = shift;
        unless ($path)
                {
                alert "Missing entry path"; return FALSE;
                }
        my $e = $self->get_entry($path);
        my %opt         = @_;
        unless ($e)
                {
                $e = ODF::lpOD::Element->create('manifest:file-entry');
                $e->set_attribute('full path' => $path);
                $e->paste_last_child($self->{context});
                }
        $e->set_type($opt{type});
        return $e;
        }

sub     del_entry
        {
        my $self        = shift;
        my $e = $self->get_entry(@_);
        $e->delete() if $e;
        return $e;
        }

#=============================================================================
1;
