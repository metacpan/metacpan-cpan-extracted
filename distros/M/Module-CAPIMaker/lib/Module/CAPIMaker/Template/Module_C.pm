package Module::CAPIMaker::Template::Module_C;

local $.;
our @template = <DATA>;
close DATA;

1;

__DATA__
/*
 * <% $module_c_filename %> - This file is in the public domain
 * Author: <% $author %>
 *
 * Generated on: <% $now %>
 * <% $module_name %> version: <% $module_version %>
 */

#include "EXTERN.h"
#include "perl.h"
#include "ppport.h"
<% $module_c_beginning %>
HV *<% $c_module_name %>_c_api_hash = NULL;
int <% $c_module_name %>_c_api_min_version = 0;
int <% $c_module_name %>_c_api_max_version = 0;

<%
    for my $n (sort keys %function) {
        my $f = $function{$n};
        $OUT .= "$f->{type} (*${c_module_name}_c_api_$n)($f->{args}) = NULL;\n";
    }
%>
int
perl_<% $c_module_name %>_load(int required_version) {
    dTHX;
    SV **svp;

    eval_pv("require <% $module_name %>", TRUE);
    if (SvTRUE(ERRSV)) return 0;

    <% $c_module_name %>_c_api_hash = get_hv("<% $module_name %>::C_API", 0);
    if (!<% $c_module_name %>_c_api_hash) {
        sv_setpv_mg(ERRSV, "Unable to load <% $module_name %> C API");
        return 0;
    }

    <% $c_module_name %>_c_api_min_version = SvIV(*hv_fetch(<% $c_module_name %>_c_api_hash, "min_version", <% length "min_version" %>, 1));
    <% $c_module_name %>_c_api_max_version = SvIV(*hv_fetch(<% $c_module_name %>_c_api_hash, "max_version", <% length "max_version" %>, 1));
    if ((required_version < <% $c_module_name %>_c_api_min_version) ||
        (required_version > <% $c_module_name %>_c_api_max_version)) {
        sv_setpvf_mg(ERRSV, 
                     "<% $module_name %> C API version mismatch. "
                     "The installed module supports versions %d to %d but %d is required",
                     <% $c_module_name %>_c_api_min_version,
                     <% $c_module_name %>_c_api_max_version,
                     required_version);
        return 0;
    }

<%
    for my $n (sort keys %function) {
        my $len = length $n;
        $OUT .= <<EOC
    svp = hv_fetch(${c_module_name}_c_api_hash, "$n", $len, 0);
    if (!svp || !*svp) {
        sv_setpv_mg(ERRSV, "Unable to fetch pointer '$n' C function from $module_name");
        return 0;
    }
    ${c_module_name}_c_api_$n = INT2PTR(void *, SvIV(*svp));
EOC
    }
%>
    return 1;
}
<% $module_c_end %>
