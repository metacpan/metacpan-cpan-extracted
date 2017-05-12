package Module::CAPIMaker::Template::Sample_XS;

local $.;
our @template = <DATA>;
close DATA;

1;

__DATA__
/*
 * <% $sample_xs_filename %> - This file is in the public domain
 * Author: <% $author %>
 *
 * Generated on: <% $now %>
 * <% $module_name %> version: <% $module_version %>
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "<% $module_h_filename %>"

MODULE = <% $module_name %>::C_API::Sample         PACKAGE = <% $module_name %>::C_API::Sample

BOOT:
    PERL_<% uc $c_module_name %>_LOAD;

