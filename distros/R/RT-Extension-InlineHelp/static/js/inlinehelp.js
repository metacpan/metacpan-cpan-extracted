// a list of entries to process for the page
var pagePopupHelpItems = [
    { selector: "[data-help]" }  // by default, anything with data-help attributes gets processed
];

if ( RT.CurrentUser.InlineHelp ) {
    pagePopupHelpItems = pagePopupHelpItems.concat(RT.CurrentUser.InlineHelp);
}

// add one or more items to the list of help entries to process for the page
function addPopupHelpItems() {
    pagePopupHelpItems = pagePopupHelpItems.concat([].slice.call(arguments));
}

function helpify($els, item={}, options={}) {
    $els.each(function(index) {
        const $el = jQuery(this);
        if ( $el.hasClass('inline-helpified') ) {
            return;
        }
        const action = $el.data("action") || item.action || options.action;
        const title = $el.data("help") || $el.data("title") || item.title;
        const content = $el.data("bs-content") || item.content;
        switch(action) {
            case "before":
                $el.before( buildPopupHelpHtml( title, content ) );
                break;
            case "after":
                $el.after( buildPopupHelpHtml( title, content ) );
                break;
            case "prepend":
                $el.prepend( buildPopupHelpHtml( title, content ) );
                break;
            case "replace":
                $el.replaceWith( buildPopupHelpHtml( title, content ) );
                break;
            case "append":
            default:
                $el.append( buildPopupHelpHtml( title, content ) );
        }
        $el.addClass('inline-helpified');
    })
}

function buildPopupHelpHtml(title, content) {
    const contentAttr = content ? ' data-bs-content="' + content + '" ' : '';
    return '<span class="popup-help" tabindex="0" role="button" data-bs-toggle="popover" title="' + title + '" data-bs-trigger="hover" ' + contentAttr + '>' + '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" fill="currentColor" class="" viewBox="0 0 16 16" role="img"><path d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14m0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16"/><path d="m8.93 6.588-2.29.287-.082.38.45.083c.294.07.352.176.288.469l-.738 3.468c-.194.897.105 1.319.808 1.319.545 0 1.178-.252 1.465-.598l.088-.416c-.2.176-.492.246-.686.246-.275 0-.375-.193-.304-.533zM9 4.5a1 1 0 1 1-2 0 1 1 0 0 1 2 0"/></svg>' + '</span>';
}

// Dynamically load the help topic corresponding to a DOM element using AJAX
// Should be called with the DOM element as the 'this' context of the function,
// making it directly compatible with the 'content' property of the popper.js
// popover() method, which is its primary purpose
const popupHelpAjax = function(elt) {
    const $el = jQuery(elt);
    var content = $el.data("bs-content");
    if (content) {
        return content;
    } else {
        const buildUrl = function(title) { return RT.Config.WebHomePath + "/Helpers/HelpTopic?title=" + encodeURIComponent(title) };
        const title = $el.data("help") || $el.data("title") || $el.data("bs-original-title");
        jQuery.ajax({
            url: buildUrl(title),
            dataType: "json",
            success: function(response, statusText, xhr) {
                $el.data('bs-content', response.content);
                $el.popover('show');
            },
            error: function(e) {
                return "<div class='text-danger'>Error loading help for '" + title + "': " + e + "</div>";
            }
        })
        return RT.I18N.Catalog.loading;
    }
}

// render all the help icons and popover-ify them
function renderPopupHelpItems( elt, list ) {
    list = list || pagePopupHelpItems;
    if (list && Array.isArray(list) && list.length) {
        list.forEach(function(entry) {
            helpify(jQuery(elt).find(entry.selector), entry);
        });
        jQuery(elt).find('[data-bs-toggle="popover"]').popover({
            trigger: 'hover',
            html: true,
            content: popupHelpAjax
        });
    }
}

if ( RT.Config.ShowInlineHelp ) {
    htmx.onLoad(elt => {
        jQuery(elt).find('.icon-helper[data-bs-toggle="tooltip"]').each( function() {
            var elem = jQuery(this);
            var help = jQuery('<span></span>');
            var title = elem.parent().text();
            help.attr('data-bs-content', this.getAttribute('title'));
            help.attr('data-help', title);
            elem.replaceWith(help);
        });

        // any help items that have been queued up via addPopupHelpItems() will
        // get their popover functionality added at this point, including the default rule
        // that matches any elements with a 'data-help' attribute
        renderPopupHelpItems(elt);
    });
}
