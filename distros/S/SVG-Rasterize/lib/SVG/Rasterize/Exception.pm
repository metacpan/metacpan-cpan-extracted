package SVG::Rasterize::Exception;
use strict;
use warnings;

use Exporter 'import';
use Scalar::Util qw(blessed);

# $Id: Exception.pm 6666 2011-04-30 07:35:53Z powergnom $

=head1 NAME

C<SVG::Rasterize::Exception> - exception classes

=head1 VERSION

Version 0.003007

=cut

our $VERSION = '0.003007';

our @EXPORT    = ();
our @EXPORT_OK = qw(ex_se_lo
                    ex_en_ov
                    ex_pa
                    ex_us_si
                    ex_us_pl
                    ex_pv
                    ex_su_iw
                    ex_su_ih
                    ex_at_ro
                    ex_pm_rl
                    ex_pm_ma_nu
                    ex_pm_mf_ne
                    ex_co_pt
                    ex_ho_bn_on
                    ie_pv
                    ie_el
                    ie_at_pv
                    ie_at_vb_nw
                    ie_at_vb_nh
                    ie_at_pd
                    ie_at_po
                    ie_at_re_nw
                    ie_at_re_nh
                    ie_at_re_nr
                    ie_at_ci_nr
                    ie_at_el_nr
                    ie_pr_pv
                    ie_pr_co_iv
                    ie_pr_st_nm
                    ie_pr_st_nd);

our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use Exception::Class (
    'SVG::Rasterize::Exception::Base'           =>
        {description => 'exception base class',
	 fields      => 'state'},
    'SVG::Rasterize::Exception::InError'        =>
        {isa         => 'SVG::Rasterize::Exception::Base',
	 description => 'document is in error'},
    'SVG::Rasterize::Exception::Setting'        =>
        {isa         => 'SVG::Rasterize::Exception::Base',
	 description => 'parse error indicating a bug'},
    'SVG::Rasterize::Exception::Engine'         =>
        {isa         => 'SVG::Rasterize::Exception::Base',
	 description => 'rasterization engine problem'},
    'SVG::Rasterize::Exception::Parse'          =>
        {isa         => 'SVG::Rasterize::Exception::Base',
	 description => 'parse error indicating a bug'},
    'SVG::Rasterize::Exception::Unsupported'    =>
        {isa         => 'SVG::Rasterize::Exception::Base',
	 description => 'unsupported feature'},
    'SVG::Rasterize::Exception::Attribute'      =>
        {isa         => 'SVG::Rasterize::Exception::Base',
	 description => 'user value failed individual check'},
    'SVG::Rasterize::Exception::ParamsValidate' =>
        {isa         => 'SVG::Rasterize::Exception::Base',
	 description => 'user value failed Params::Validate check'},
    'SVG::Rasterize::Exception::Param'          =>
        {isa         => 'SVG::Rasterize::Exception::Base',
	 description => 'user value failed individual check'},
    'SVG::Rasterize::Exception::Return'         =>
        {isa         => 'SVG::Rasterize::Exception::Base',
	 description => 'invalid return value'}
);

sub _get_env {
    my ($caller) = @_;

    return(undef, undef) if(!$caller or !blessed($caller));
    if($caller->isa('SVG::Rasterize')) {
	return($caller, $caller->state);
    }
    elsif($caller->isa('SVG::Rasterize::State')) {
	return($caller->rasterize, $caller);
    }
    else {
	my $message = "Unexpected caller '$caller' in exception ".
	    "handling. Please report this as a bug.\n";
	SVG::Rasterize::Exception::Base->throw
	    (state   => undef,
	     message => $message);
    }
}

sub _compose_message {
    my ($template, @values) = @_;
    my $name                = (caller 1)[3];

    foreach($template, @values) {
	if(!defined($_)) {
	    return("Stumbled over undefined value while composing ".
		   "error method for exception $name. Please report ".
		   "this as a bug.\n");
	}
    }

    return sprintf($template, @values);
}

sub ex_se_lo {
    my ($caller, $value, $syserror) = @_;
    my ($rasterize, $state)         = _get_env($caller);
    my $template                    = "Unable to load %s: %s.\n";
    
    SVG::Rasterize::Exception::Setting->throw
	(state   => $state,
	 message => _compose_message($template, $value, $syserror));
}

sub ex_en_ov {
    my ($caller, $method, $class) = @_;
    my ($rasterize, $state)       = _get_env($caller);
    my $template                  =
	"Method %s not overloaded in class %s.\n";
    
    SVG::Rasterize::Exception::Setting->throw
	(state   => $state,
	 message => _compose_message($template, $method, $class));
}

sub ex_pa {
    my ($caller, $desc, $value) = @_;
    my ($rasterize, $state)     = _get_env($caller);
    my $template                =
	"Failed to process the %s string '%s' correctly. Please ".
	"report this as a bug and include the string into the bug ".
	"report.\n";

    SVG::Rasterize::Exception::Parse->throw
	(state   => $state,
	 message => _compose_message($template, $desc, $value));
}

sub ex_us_si {
    my ($caller, $desc)     = @_;
    my ($rasterize, $state) = _get_env($caller);
    my $template            = "%s is currently unsupported.\n";

    SVG::Rasterize::Exception::Unsupported->throw
	(state   => $state,
	 message => _compose_message($template, $desc));
}

sub ex_us_pl {
    my ($caller, $desc)     = @_;
    my ($rasterize, $state) = _get_env($caller);
    my $template            = "%s are currently unsupported.\n";

    SVG::Rasterize::Exception::Unsupported->throw
	(state   => $state,
	 message => _compose_message($template, $desc));
}

sub ex_pv {
    my ($caller, $message)  = @_;
    my ($rasterize, $state) = _get_env($caller);

    SVG::Rasterize::Exception::ParamsValidate->throw
	(state   => $state,
	 message => _compose_message($message));
}

sub ex_su_iw {
    my ($caller, $value)    = @_;
    my ($rasterize, $state) = _get_env($caller);
    my $template            = "Invalid surface width %s.\n";

    SVG::Rasterize::Exception::Param->throw
	(state   => $state,
	 message => _compose_message($template, $value));
}

sub ex_su_ih {
    my ($caller, $value)    = @_;
    my ($rasterize, $state) = _get_env($caller);
    my $template            = "Invalid surface height %s.\n";

    SVG::Rasterize::Exception::Param->throw
	(state   => $state,
	 message => _compose_message($template, $value));
}

sub ex_at_ro {
    my ($caller, $value)    = @_;
    my ($rasterize, $state) = _get_env($caller);
    my $template            = "Attribute %s is readonly.\n";

    SVG::Rasterize::Exception::Attribute->throw
	(state   => $state,
	 message => _compose_message($template, $value));
}

sub ex_pm_rl {
    my ($caller, $value)    = @_;
    my ($rasterize, $state) = _get_env($caller);
    my $template            = "Unexpected relative length (%s).\n";

    SVG::Rasterize::Exception::Param->throw
	(state   => $state,
	 message => _compose_message($template, $value));
}

sub ex_pm_ma_nu {
    my ($caller, $value)    = @_;
    my ($rasterize, $state) = _get_env($caller);
    my $template            =
	"Entry '%s' in coordinate transformation matrix does not ".
	"look like a number.\n";

    SVG::Rasterize::Exception::Param->throw
	(state   => $state,
	 message => _compose_message($template, $value));
}

sub ex_pm_mf_ne {
    my ($caller, $value)    = @_;
    my ($rasterize, $state) = _get_env($caller);
    my $template            = "Non-positive medium font-size (%s).\n";

    SVG::Rasterize::Exception::Param->throw
	(state   => $state,
	 message => _compose_message($template, $value));
}

sub ex_co_pt {
    my ($caller)            = @_;
    my ($rasterize, $state) = _get_env($caller);
    my $template            =
	"No Method 'text' or 'textPath' ancestor for%s element%s.\n";
    
    my @strings = ('', '');
    if($state) {
	$strings[0] = ' '.$state->node_name;
	if(my $id = $state->node_attributes->{id}) {
	    $strings[1] .= " with id $id";
	}
    }

    SVG::Rasterize::Exception::Param->throw
	(state   => $state,
	 message => _compose_message($template, @strings));
}

sub ex_ho_bn_on {
    my ($caller)            = @_;
    my ($rasterize, $state) = _get_env($caller);
    my $message             =
	"The before_node_hook returned no or an odd number of elements. ".
	"Looks like you forgot to return a hash from a custom hook.\n";
    
    SVG::Rasterize::Exception::Return->throw
	(state   => $state,
	 message => _compose_message($message));
}

sub ie_pv {
    my ($caller, $message)  = @_;
    my ($rasterize, $state) = _get_env($caller);

    my $ex = SVG::Rasterize::Exception::InError->new
	(state   => $state,
	 message => _compose_message($message));

    if($rasterize) { $rasterize->in_error($ex) }
    else           { die $ex }
}

sub ie_el {
    my ($caller, $child, $parent) = @_;
    my ($rasterize, $state)       = _get_env($caller);
    my $template                  = $parent
	? "Element '%s' is not a valid child of element '%s'."
	: "Element '%s' is not a valid SVG element.\n";

    my $ex = SVG::Rasterize::Exception::InError->new
	(state   => $state,
	 message => _compose_message($template, $child, $parent));

    if($rasterize) { $rasterize->in_error($ex) }
    else           { die $ex }
}

sub ie_at_pv {
    my ($caller, $message)  = @_;
    my ($rasterize, $state) = _get_env($caller);
    my $template                     =
	"Attribute failed validation:\n%s\n";

    my $ex = SVG::Rasterize::Exception::InError->new
	(state   => $state,
	 message => _compose_message($template, $message));

    if($rasterize) { $rasterize->in_error($ex) }
    else           { die $ex }
}

sub ie_at_vb_nw {
    my ($caller, $value)    = @_;
    my ($rasterize, $state) = _get_env($caller);
    my $template            = "Negative viewBox width (%s).\n";

    my $ex = SVG::Rasterize::Exception::InError->new
	(state   => $state,
	 message => _compose_message($template, $value));

    if($rasterize) { $rasterize->in_error($ex) }
    else           { die $ex }
}

sub ie_at_vb_nh {
    my ($caller, $value)    = @_;
    my ($rasterize, $state) = _get_env($caller);
    my $template            = "Negative viewBox height (%s).\n";

    my $ex = SVG::Rasterize::Exception::InError->new
	(state   => $state,
	 message => _compose_message($template, $value));

    if($rasterize) { $rasterize->in_error($ex) }
    else           { die $ex }
}

sub ie_at_pd {
    my ($caller, $value)    = @_;
    my ($rasterize, $state) = _get_env($caller);
    my $template            = "Path data string '%s' is invalid.\n";

    my $ex = SVG::Rasterize::Exception::InError->new
	(state   => $state,
	 message => _compose_message($template, $value));

    if($rasterize) { $rasterize->in_error($ex) }
    else           { die $ex }
}

sub ie_at_po {
    my ($caller, $value)    = @_;
    my ($rasterize, $state) = _get_env($caller);
    my $template            = "Points string '%s' is invalid.\n";

    my $ex = SVG::Rasterize::Exception::InError->new
	(state   => $state,
	 message => _compose_message($template, $value));

    if($rasterize) { $rasterize->in_error($ex) }
    else           { die $ex }
}

sub ie_at_re_nw {
    my ($caller, $value)    = @_;
    my ($rasterize, $state) = _get_env($caller);
    my $template            = "Negative rectangle width %s.\n";

    my $ex = SVG::Rasterize::Exception::InError->new
	(state   => $state,
	 message => _compose_message($template, $value));

    if($rasterize) { $rasterize->in_error($ex) }
    else           { die $ex }
}

sub ie_at_re_nh {
    my ($caller, $value)    = @_;
    my ($rasterize, $state) = _get_env($caller);
    my $template            = "Negative rectangle height %s.\n";

    my $ex = SVG::Rasterize::Exception::InError->new
	(state   => $state,
	 message => _compose_message($template, $value));

    if($rasterize) { $rasterize->in_error($ex) }
    else           { die $ex }
}

sub ie_at_re_nr {
    my ($caller, $value)    = @_;
    my ($rasterize, $state) = _get_env($caller);
    my $template            = "Negative rectangle corner radius %s.\n";

    my $ex = SVG::Rasterize::Exception::InError->new
	(state   => $state,
	 message => _compose_message($template, $value));

    if($rasterize) { $rasterize->in_error($ex) }
    else           { die $ex }
}

sub ie_at_ci_nr {
    my ($caller, $value)    = @_;
    my ($rasterize, $state) = _get_env($caller);
    my $template            = "Negative circle radius %s.\n";

    my $ex = SVG::Rasterize::Exception::InError->new
	(state   => $state,
	 message => _compose_message($template, $value));

    if($rasterize) { $rasterize->in_error($ex) }
    else           { die $ex }
}

sub ie_at_el_nr {
    my ($caller, $value)    = @_;
    my ($rasterize, $state) = _get_env($caller);
    my $template            = "Negative ellipse radius %s.\n";

    my $ex = SVG::Rasterize::Exception::InError->new
	(state   => $state,
	 message => _compose_message($template, $value));

    if($rasterize) { $rasterize->in_error($ex) }
    else           { die $ex }
}

sub ie_pr_pv {
    my ($caller, $name, $message) = @_;
    my ($rasterize, $state)       = _get_env($caller);
    my $template                     =
	"Property %s failed validation:\n%s\n";

    my $ex = SVG::Rasterize::Exception::InError->new
	(state   => $state,
	 message => _compose_message($template, $name, $message));

    if($rasterize) { $rasterize->in_error($ex) }
    else           { die $ex }
}

sub ie_pr_co_iv {
    my ($caller, $value)    = @_;
    my ($rasterize, $state) = _get_env($caller);
    my $template            = "Invalid color specification %s.\n";

    my $ex = SVG::Rasterize::Exception::InError->new
	(state   => $state,
	 message => _compose_message($template, $value));

    if($rasterize) { $rasterize->in_error($ex) }
    else           { die $ex }
}

sub ie_pr_st_nm {
    my ($caller, $value)    = @_;
    my ($rasterize, $state) = _get_env($caller);
    my $template            =
	"Value of stroke-miterlimit (%s) out of range (must be at ".
	"least 1).\n";

    my $ex = SVG::Rasterize::Exception::InError->new
	(state   => $state,
	 message => _compose_message($template, $value));

    if($rasterize) { $rasterize->in_error($ex) }
    else           { die $ex }
}

sub ie_pr_st_nd {
    my ($caller, $value)    = @_;
    my ($rasterize, $state) = _get_env($caller);
    my $template            =
	"Negative value (%s) in stroke-dasharray.\n";

    my $ex = SVG::Rasterize::Exception::InError->new
	(state   => $state,
	 message => _compose_message($template, $value));

    if($rasterize) { $rasterize->in_error($ex) }
    else           { die $ex }
}


1;


__END__

=pod

=head1 DESCRIPTION

This module uses L<Exception::Class|Exception::Class> to define a
set of exception classes and provides a list of short hand
subroutines to throw these exceptions.

=head2 Error Messages

The following list will eventually contain all error messages
produced by the C<SVG::Rasterize> distribution.

=over 4

=item * ...

=back

=head2 Subroutines offered for Import

Most of these functions will be completely useless to you. The
documentation is mainly for myself. The idea behind this is that an
object that wants to throw an exception needs to use as few code as
possible thereby avoiding too much disturbance of a
reader. Additionally, the precise phrasing of the messages can be
kept at a central place.

All of the routines are supposed to be called as methods of (both
are possible) either L<SVG::Rasterize|SVG::Rasterize> or
L<SVG::Rasterize::State|SVG::Rasterize::State>. The reason for this
is that the C<State> object will be given to the exception object
and the C<Rasterize> object is needed to call its
L<in_error|SVG::Rasterize/in_error> method. However, on request this
requirement could be relaxed to that the object on which the methods
are called has to provide either a C<state> or a C<rasterize> method
which then provides the respective objects.

=over 4

=item * ex_se_lo

Stands for "exception settings load".

=item * ex_en_ov

Stands for "exception engine overload".

=item * ex_pa

Stands for "exception parse".

=item * ex_us_si

Stands for "exception unsupported singular".

=item * ex_us_pl

Stands for "exception unsupported plural".

=item * ex_pv

Stands for "exception C<Params::Validate>".

=item * ex_su_iw

Stands for "exception surface invalid width".

=item * ex_su_ih

Stands for "exception surface invalid height".

=item * ex_at_ro

Stands for "exception attribute readonly".

=item * ex_pm_rl

Stands for "exception parameter relative length".

=item * ex_pm_ma_nu

Stands for "exception parameter matrix number".

=item * ex_pm_mf_ne

Stands for "exception parameter medium font-size negative".

=item * ex_co_pt

Stands for "exception context parent text".

=item * ex_ho_bn_on

Stands for "exception hook before_node odd number".

=item * ie_pv

Stands for "in error C<Params::Validate>". Should be used if it
cannot be determined where the incriminated value came from (see
L<ie_at_pv|/ie_at_pv>).
L<map_length|SVG::Rasterize::State/map_length> in
C<SVG::Rasterize::State> uses this function although the value will
be an attribute.

=item * ie_el

Stands for "in error element".

=item * ie_at_pv

Stands for "in error attribute C<Params::Validate>". Should be used
if it is sure that it is an attribute that failed the
validation. L<_process_node|SVG::Rasterize::State/_process_node> in
C<SVG::Rasterize::State> uses this function. Probably all others
should use L<ie_pv|/ie_pv>.

=item * ie_at_vb_nw

Stands for "in error attribute viewBox negative width".

=item * ie_at_vb_nh

Stands for "in error attribute viewBox negative height".

=item * ie_at_pd

Stands for "in error attribute path data".

=item * ie_at_po

Stands for "in error attribute points".

=item * ie_at_re_nw

Stands for "in error attribute rectangle negative width".

=item * ie_at_re_nh

Stands for "in error attribute rectangle negative height".

=item * ie_at_re_nr

Stands for "in error attribute rectangle negative (corner) radius".

=item * ie_at_ci_nr

Stands for "in error attribute circle negative radius".

=item * ie_at_el_nr

Stands for "in error attribute ellipse negative radius".

=item * ie_pr_pv

Stands for "in error property C<Params::Validate>".

=item * ie_pr_co_iv

Stands for "in error property color invalid value".

=item * ie_pr_st_nm

Stands for "in error property stroke negative miter limit".

=item * ie_pr_st_nd

Stands for "in error property stroke negative (value in) dash array".

=back

=head1 SEE ALSO

=over 4

=item * L<SVG::Rasterize|SVG::Rasterize>

=item * L<Exception::Class|Exception::Class>

=back


=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify
it under the terms of either: the GNU General Public License as
published by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
