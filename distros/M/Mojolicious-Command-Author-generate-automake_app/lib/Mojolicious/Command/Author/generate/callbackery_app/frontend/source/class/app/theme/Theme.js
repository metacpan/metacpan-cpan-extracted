/* ************************************************************************
   Copyright: <%= ${year} %> <%= ${fullName} %>
   License:   ???
   Authors:   <%= ${fullName} %> <<%= ${email} %>>
 *********************************************************************** */
qx.Theme.define("<%= ${class_file} %>.theme.Theme", {
    meta : {
        color : callbackery.theme.Color,
        decoration : callbackery.theme.Decoration,
        font : callbackery.theme.Font,
        icon : qx.theme.icon.Tango,
        appearance : callbackery.theme.Appearance
    }
});
