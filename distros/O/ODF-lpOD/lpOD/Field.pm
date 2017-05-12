#=============================================================================
#
#       Copyright (c) 2010 Ars Aperta, Itaapy, Pierlis, Talend.
#       Copyright (c) 2012 Jean-Marie Gouarné.
#       Author: Jean-Marie Gouarné <jean.marie.gouarne@online.fr>
#
#=============================================================================
use     5.010_001;
use     strict;
use     experimental    'smartmatch';
#=============================================================================
#       Variable fields
#=============================================================================
package ODF::lpOD::Field;
use base 'ODF::lpOD::Element';
our $VERSION    = '1.003';
use constant PACKAGE_DATE => '2012-03-28T09:14:15';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     _create { ODF::lpOD::Field->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        my $tag         = shift;
        unless ($tag)
                {
                alert "Missing element tag";
                return FALSE;
                }
        my %opt = process_options
                (
                type    => 'string',
                value   => undef,
                text    => undef,
                @_
                );
        my $field = ODF::lpOD::Element->create($tag);
        unless ($field)
                {
                alert "Field $tag creation failure";
                return FALSE;
                }
        bless $field, __PACKAGE__;
        $field->set_name($opt{name});
        if (defined $opt{text})
                {
                $field->set_text($opt{text});
                delete $opt{text};
                }
        unless ($field->set_type($opt{type}))
                {
                alert "Type setting failure";
                $field->delete; return FALSE;
                }
        if (defined $opt{value})
                {
                unless ($field->set_value($opt{value}))
                        {
                        alert "Value setting failure";
                        $field->delete; return FALSE;
                        }
                }

        return $field;
        }

#-----------------------------------------------------------------------------

sub     get_type
        {
        my $self        = shift;
        return $self->att('office:value-type') // 'string';
        }

sub     set_type
        {
        my $self        = shift;
        my $type        = shift;
        given ($type)
                {
                when (undef)
                        {
                        $self->del_attribute('office:value-type');
                        $self->del_attribute('office:currency');
                        }
                when ([@ODF::lpOD::Common::DATA_TYPES])
                        {
                        $self->set_att('office:value-type', $type);
                        $self->del_attribute('office:currency')
                                        unless $type eq 'currency';
                        }
                default
                        {
                        alert "Wrong data type"; $type = FALSE;
                        }
                }
        return $type;
        }

sub     get_currency
        {
        my $self        = shift;
        return $self->att('office:currency');
        }

sub     set_currency
        {
        my $self        = shift;
        my $currency    = shift;
        $self->set_type('currency') if $currency;
        return $self->set_att('office:currency', $currency);
        }

sub     get_value
        {
        my $self        = shift;
        my $type        = $self->get_type();
        my $value;
        given ($type)
                {
                when ('string')
                        {
                        $value = $self->get_attribute('office:string-value');
                        }
                when (['date', 'time'])
                        {
                        my $attr = 'office:' . $type . '-value';
                        $value = $self->att($attr);
                        }
                when (['float', 'currency', 'percentage'])
                        {
                        $value = $self->att('office:value');
                        }
                when ('boolean')
                        {
                        my $v = $self->att('office:boolean-value');
                        $value = defined $v ? is_true($v) : undef;
                        }
                }
        return wantarray ? ($value, $type) : $value;
        }

sub     set_value
        {
        my $self        = shift;
        my $value       = shift;
        return undef unless defined $value;
        my $type        = $self->get_type();

        my $v = check_odf_value($value, $type);
        given ($type)
                {
                when ('string')
                        {
                        $self->set_attribute('office:string-value' => $v);
                        }
                when ('date')
                        {
                        if (is_numeric($v))
                                {
                                $v = iso_date($v);
                                }
                        $self->set_att('office:date-value', $v);
                        }
                when ('time')
                        {
                        $self->set_att('office:time-value', $v);
                        }
                when (['float', 'currency', 'percentage'])
                        {
                        $self->set_att('office:value', $v);
                        }
                when ('boolean')
                        {
                        $self->set_att('office:boolean-value', $v);
                        }
                }
        return $self->get_value;
        }

#=============================================================================
package ODF::lpOD::Variable;
use base 'ODF::lpOD::Field';
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2010-12-24T13:58:47';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     set_text
        {
        my $self        = shift;
        my $type = $self->get_type;
        unless ($type eq 'text')
                {
                alert "Text not allowed for $type variables";
                return FALSE;
                }
        return $self->set_attribute('office:string-value' => shift);
        }

sub     get_text
        {
        my $self        = shift;
        return $self->get_attribute('office:string-value');
        }

#=============================================================================
package ODF::lpOD::UserVariable;
use base 'ODF::lpOD::Variable';
our $VERSION    = '1.002';
use constant PACKAGE_DATE => '2012-03-14T15:26:44';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     context_tag     { 'text:user-field-decls' }
sub     context_path    { CONTENT, ('//' . context_tag) }

sub     _create { ODF::lpOD::UserVariable->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        return bless
                ODF::lpOD::Field->create('text:user-field-decl', @_),
                __PACKAGE__;
        }

#=============================================================================
package ODF::lpOD::SimpleVariable;
use base 'ODF::lpOD::Variable';
our $VERSION    = '1.002';
use constant PACKAGE_DATE => '2012-03-14T15:28:42';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     context_tag     { 'text:variable-decls'}
sub     context_path    { CONTENT, ('//' . context_tag) }

#-----------------------------------------------------------------------------

sub     _create { ODF::lpOD::SimpleVariable->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        return bless
                ODF::lpOD::Field->create('text:variable-decl', @_),
                __PACKAGE__;
        }

#-----------------------------------------------------------------------------

sub     set_value       {}
sub     get_value       {}

#=============================================================================
package ODF::lpOD::TextField;
use base 'ODF::lpOD::Field';
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2010-12-24T13:59:24';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

our @TYPES =
        (
        'date', 'time', 'page number', 'page continuation', 'page count',
        'sender firstname', 'sender lastname', 'sender initials',
        'sender title', 'sender position', 'sender email',
        'sender phone private', 'sender fax', 'sender company',
        'sender phone work', 'sender street', 'sender postal code',
        'sender city', 'sender country', 'sender state or province',
        'creator', 'author name', 'author initials', 'chapter', 'file name',
        'template name', 'sheet name', 'title', 'subject',
        'user field get', 'variable'
        );

sub     check_type
        {
        my $type        = shift;
        return ($type ~~ [@TYPES]) ? $type : FALSE;
        }

sub     types           { @TYPES }

sub     classify
        {
        my $arg         = shift;
        my ($tag, $elt, $class);
        if (ref $arg)
                {
                $elt = $arg;
                $tag = $elt->get_tag;
                }
        else
                {
                $tag = $arg;
                }
        return undef unless $tag =~ /^text:/;
        $tag =~ s/^.*://; $tag =~ s/-/ /g;
        if ($tag ~~ [@TYPES])
                {
                $class = __PACKAGE__;
                return $elt ? bless $elt, $class : $class;
                }
        return undef;
        }

sub	set_class
	{
	my $self	= shift;
	return classify($self);
	}

sub	set_style
	{
	my $self	= shift;
	return $self->set_attribute('style:data-style-name' => shift);
	}

sub	get_style
	{
	my $self	= shift;
	return $self->get_attribute('style:data-style-name');
	}

#-----------------------------------------------------------------------------

sub     get_value
        {
        my $self        = shift;
        my $att = $self->get_tag() . '-value';
        return $self->get_attribute($att) // $self->get_text;
        }

sub     set_value       { my $self = shift; $self->not_allowed }
sub     set_text        { my $self = shift; $self->not_allowed }

#=============================================================================
1;
