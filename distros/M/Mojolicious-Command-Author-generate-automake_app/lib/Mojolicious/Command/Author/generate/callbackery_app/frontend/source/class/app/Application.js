/* ************************************************************************
   Copyright: <%= ${year} %> <%= ${fullName} %>
   License:   ???
   Authors:   <%== ${fullName} %> <<%= ${email} %>>
 *********************************************************************** */

/**
 * Main application class.
 * @asset(<%= ${class_file} %>/*)
 *
 */
qx.Class.define("<%= ${class_file} %>.Application", {
    extend : callbackery.Application,
    members : {
        main : function() {
            // Call super class
            this.base(arguments);
        }
    }
});
