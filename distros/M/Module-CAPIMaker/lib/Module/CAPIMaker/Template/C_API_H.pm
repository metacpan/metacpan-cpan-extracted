package Module::CAPIMaker::Template::C_API_H;

local $.;
our @template = <DATA>;
close DATA;

1;

__DATA__

/*
 * <% $c_api_h_filename %> - This file is in the public domain
 * Author: <% $author %>
 *
 * Generated on: <% $now %>
 * <% $module_name %> version: <% $module_version %>
 */

#if !defined (<% $c_api_h_barrier %>)
#define <% $c_api_h_barrier %>

static void
init_c_api(pTHX) {
    HV *hv = get_hv("<% $module_name %>::C_API", TRUE|GV_ADDMULTI);
    hv_store(hv, "min_version", <% length("min_version") %>, newSViv(<% $min_version %>), 0);
    hv_store(hv, "max_version", <% length("max_version") %>, newSViv(<% $max_version %>), 0);
<%
    for my $n (sort keys %function) {
        my $f = $function{$n};
        my $len = length $n;
        $OUT .= "    hv_store(hv, \"$n\", $len, newSViv(PTR2IV(&$n)), 0);\n";
    }
%>
}

#define INIT_C_API init_c_api(aTHX)

#endif
