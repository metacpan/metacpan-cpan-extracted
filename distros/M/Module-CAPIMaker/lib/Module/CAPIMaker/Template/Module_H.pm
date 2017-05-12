package Module::CAPIMaker::Template::Module_H;

local $.;
our @template = <DATA>;
close DATA;

1;

__DATA__
/*
 * <% $module_h_filename %> - This file is in the public domain
 * Author: <% $author %>
 *
 * Generated on: <% $now %>
 * <% $module_name %> version: <% $module_version %>
 */

#if !defined (<% $module_h_barrier %>)
#define <% $module_h_barrier %>

#define <% uc $c_module_name %>_C_API_REQUIRED_VERSION <% $max_version %>
<% $module_h_beginning %>
int perl_<% $c_module_name %>_load(int required_version);

#define PERL_<% uc $c_module_name %>_LOAD perl_<% $c_module_name %>_load(<% uc $c_module_name %>_C_API_REQUIRED_VERSION)
#define PERL_<% uc $c_module_name %>_LOAD_OR_CROAK \
    if (PERL_<% uc $c_module_name %>_LOAD);        \
    else croak(NULL);

extern HV *<% $c_module_name %>_c_api_hash;
extern int <% $c_module_name %>_c_api_min_version;
extern int <% $c_module_name %>_c_api_max_version;

<%
    for my $n (sort keys %function) {
        my $f = $function{$n};
        my $var = "${c_module_name}_c_api_$n";
        $OUT .= "extern $f->{type} (*$var)($f->{args});\n";
        if ($f->{pTHX}) {
            $OUT .= "#define $export_prefix$n($f->{macro_args}) ((*$var)($f->{call_args}))\n";
        }
        else {
            $OUT .= "#define $export_prefix$n (*$var)\n";
        }
    }
%>
<% $module_h_end %>
#endif
