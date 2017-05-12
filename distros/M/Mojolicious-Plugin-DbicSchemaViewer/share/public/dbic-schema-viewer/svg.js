var pressedKeys = {
    ctrl: false,
    shift: false,
    alt: false,
};
$(document).ready(function() {
    var $doc = $('svg');

    $doc.find('.edge')
        .hover(function(e) {
            var $edge = $(this);

            $edge.addClass('hovered');
            $edge.appendTo($edge.parent());
            $edge.css('cursor', 'pointer');
        })
        .mouseout(function(e) {
            var $edge = $(this);

            if(!$edge.attr('data-clicked')) {
                $edge.removeClass('hovered');
            }
        })
        .click(function(e) {
            var $edge = $(this);
            if($edge.attr('data-clicked')) {
                $edge.removeAttr('data-clicked');
            }
            else {
                $edge.attr('data-clicked', 1);
            }
        });

    // Handle column name hovers
    $doc.find('polygon.column-name, text.column-name')
        .mouseenter(function(e) {
            var $selected = $(this);
            var $text = $selected.prop('tagName') === 'text' ? $selected : $selected.siblings(byColumnTextIdFromPolygon($selected));
            var $polygon = $selected.prop('tagName') === 'polygon' ? $selected : $selected.siblings(byColumnPolygonIdFromText($selected));

            $polygon.addClass('hovered');
            highlightRelation($doc, $text.parent().data('table-name'), $text.data('column-name'));
        })
        .mouseout(function(e) {
            var $selected = $(this);
            var $text = $selected.prop('tagName') === 'text' ? $selected : $selected.siblings(byColumnTextIdFromPolygon($selected));
            var $polygon = $selected.prop('tagName') === 'polygon' ? $selected : $selected.siblings(byColumnPolygonIdFromText($selected));

            if($text.attr('data-clicked')) {
                return;
            }
            $polygon.removeClass('hovered');
            removeDependentHighlights($doc, $text.parent().data('table-name') + '.' + $text.data('column-name'));
        })
        .click(function(e) {
            var $text = $(this).prop('tagName') === 'text' ? $(this) : $(this).siblings(byColumnTextIdFromPolygon($(this)));

            if($text.attr('data-clicked')) {
                $text.removeAttr('data-clicked');
            }
            else {
                $text.attr('data-clicked', 1);
            }
        });

    // Highlight all relations to/from a table when the table name cell is hovered.
    $doc.find('polygon.table-name, text.table-name')
        .mouseenter(function(e) {
            var $node = $(this).parent();

            if(!$node.hasClass('unwanted')) {
                $node.addClass('hovered').removeClass('faded');
                highlightRelation($doc, $node.data('table-name'));
            }
        })
        .mouseout(function(e) {
            var $node = $(this).parent();

            if($node.hasClass('unwanted')) {
                $node.removeClass('hovered');
            }
            if($node.attr('data-clicked')) {
                return;
            }
            $node.removeClass('hovered');
            removeDependentHighlights($doc, $node.data('table-name'));
        })
        .click(function(e) {
            var $node = $(this).parent();

            var params = allParams();
            if(pressedKeys['shift'] && pressedKeys['ctrl']) {
                var skip = params['skip_result_source_names'] ? params['skip_result_source_names'].split(',') : [];
                skip.push($node.data('table-name'));
                params['skip_result_source_names'] = skip.join(',');

                //params['skip_result_source_names'] = $node.data('table-name');
                window.location = paramToQueryString(params);
            }
            else if(pressedKeys['shift']) {
                params['wanted_result_source_names'] = $node.data('table-name');
                window.location = paramToQueryString(params);
            }

            if($node.attr('data-clicked')) {
                $node.removeAttr('data-clicked');
            }
            else {
                $node.attr('data-clicked', 1);
            }
            if(pressedKeys['ctrl'] && $node.attr('data-clicked')) {
                $node.addClass('unwanted').removeClass('hovered');
                removeDependentHighlights($doc, $node.data('table-name'));
            }
            else {
                    $node.removeClass('unwanted');
                    highlightRelation($doc, $node.data('table-name'));
            }
    });

    $doc.find('.node *')
        .mouseenter(function() {
            $(this).parent().addClass('mouseover').removeClass('faded');
        })
        .mouseout(function() {
            $(this).parent().removeClass('mouseover');
        });

    $(document).keyup(function(e) {
        // escape -> restore (but only if the #help-modal isn't opened)
        if(e.keyCode === 27 && $('#help-modal').css('display') === 'none') {
            $doc.find('.edge').removeClass('hovered active').removeAttr('data-clicked');
            $doc.find('.node').removeClass('hovered related-table faded unwanted').removeAttr('data-clicked');
            $doc.find('.node polygon').removeClass('hovered').removeAttr('data-clicked');
            $doc.find('text').removeClass('hovered').removeAttr('data-clicked');
            $doc.find('[data-highlighted-by]').removeAttr('data-highlighted-by');
        }
        // r -> zoom to selected tables
        else if(isKey(e, 'R')) {
            var params = allParams();
            var wanted = [];
            var skip = params['skip_result_source_names'] ? params['skip_result_source_names'].split(',') : [];

            $doc.find('.node.hovered').each(function() {
                wanted.push($(this).data('table-name'));
            });
            $doc.find('.node.unwanted').each(function() {
                skip.push($(this).data('table-name'));
            })

            if(wanted.length) {
                params['wanted_result_source_names'] = wanted.join(',');
            }
            if(skip.length) {
                params['skip_result_source_names'] = skip.join(',');
            }
            window.location = paramToQueryString(params);
        }
        // k -> Redraws with the current wanted/skipped, but toggle only_keys
        else if(isKey(e, 'K')) {
            var params = allParams();

            if(params['only_keys'] !== undefined && params['only_keys'] === '1') {
                params['only_keys'] = 0;
            }
            else {
                params['only_keys'] = 1;
            }
            window.location = paramToQueryString(params);
        }
        // q -> back to overall visualization
        else if(isKey(e, 'Q')) {
            window.location = '?';
        }
        // 0..9 -> degrees_of_separation
        else if(e.keyCode >= 48 && e.keyCode <= 57) {
            e.preventDefault();
            var params = allParams();
            var degrees = e.keyCode - 48;

            if(pressedKeys['shift']) {
                degrees += 10;
            }
            if(pressedKeys['ctrl']) {
                degrees += 20;
            }
            params['degrees_of_separation'] = degrees;
            window.location = paramToQueryString(params);
        }
    });

    // remember shift/ctrl status
    $(document).keydown(function(e) {
            if(e.ctrlKey) {
                pressedKeys['ctrl'] = true;
            }
            if(e.shiftKey) {
                pressedKeys['shift'] = true;
            }
        })
        .keyup(function(e) {
            if(!e.ctrlKey) {
                pressedKeys['ctrl'] = false;
            }
            if(!e.shiftKey) {
                pressedKeys['shift'] = false;
            }
        });

    if(param('wanted_result_source_names')) {
        var tableNames = param('wanted_result_source_names').split(',');
        var findString = tableNames.map(tableName => '.node' + byAttr('data-table-name', tableName) + ' polygon.table-name').join(', ');
        $(findString).mouseenter().click();
    }

});
// call byAttr('data-column-name', $el)     instead of  '[data-column-name="' + $el.attr('data-column-name') + '"]'
//   or byAttr('data-column-name', string)  instead of  '[data-column-name="' + string + '"]'
function byAttr(attr, thing, operand) {
    var string = typeof thing === 'object' ? thing.attr(attr) : thing;
    var operand = operand || '=';
    return '[' + attr + operand + '"' + string + '"]';
}

// polygon.column-name has id 'bg-column-%s'
// text.column-name    has id 'column-%s'
function byColumnTextIdFromPolygon($polygon) {
    return '#' + $polygon.attr('id').replace(/^bg-/, '');
}
function byColumnPolygonIdFromText($text) {
    return '#bg-' + $text.attr('id');
}

function addHighlightedBy($el, by) {
    if($el.attr('data-highlighted-by')) {
        var currentvalue = $el.attr('data-highlighted-by');
        if(!currentvalue.match(new RegExp('#' + by + '#'))) {
            var newValue = $el.attr('data-highlighted-by') + '#' + by + '#';
            $el.attr('data-highlighted-by', newValue);
        }
    }
    else {
        $el.attr('data-highlighted-by', '#' + by + '#');
    }
}
function removeDependentHighlights($doc, by) {
    by = '#' + by + '#';
    $doc.find('.edge' + byAttr('data-highlighted-by', by, '*=')).each(function() {
        var $edge = $(this);
        _removeHighlightHelper($edge, by);
        if(!$edge.attr('data-highlighted-by')) { $edge.removeClass('active'); }
    });
    $doc.find('.node' + byAttr('data-highlighted-by', by, '*=')).each(function() {
        var $node = $(this);
        _removeHighlightHelper($node, by);
        if(!$node.attr('data-highlighted-by')) { $node.removeClass('related-table'); }
    });

    // Add fadedness to nodes if any other node is a .related-table.
    // Otherwise, remove fadedness from all.
    if($doc.find('.node.related-table').length) {
        $doc.find('.node:not(.related-table):not(.hovered):not(.unwanted)').addClass('faded');
    }
    else {
        $doc.find('.node.faded').removeClass('faded');
    }
}
// by must be '#by#'
function _removeHighlightHelper($el, by) {
    $el.attr('data-highlighted-by', $el.attr('data-highlighted-by').replace(new RegExp(by, 'g'), ''));
    if(!$el.attr('data-highlighted-by')) {
        $el.removeAttr('data-highlighted-by');
    }
}
function getEdgesByTableColumn(table, column) {
    return '.edge' + byAttr('data-origin-table', table) + byAttr('data-origin-column', column)
       + ', .edge' + byAttr('data-destination-table', table) + byAttr('data-destination-column', column);
}
function highlightRelation($doc, tableName, columnName) {
    var byOrigin = byAttr('data-origin-table', tableName);
    var byDestination = byAttr('data-destination-table', tableName);

    if(undefined !== columnName) {
        byOrigin = byOrigin + byAttr('data-origin-column', columnName);
        byDestination = byDestination + byAttr('data-destination-column', columnName);
    }
    var by = tableName + (columnName !== undefined ? '.'+columnName : '');
    $doc.find('.edge' + byOrigin + ', .edge' + byDestination).each(function(index) {
        var $edge = $(this);
        $edge.addClass('active');
        $edge.appendTo($edge.parent());

        var otherTableName = tableName === $edge.data('origin-table') ? $edge.data('destination-table') : $edge.data('origin-table');
        var $otherTable = $doc.find('.node' + byAttr('data-table-name', otherTableName));

        addHighlightedBy($edge, by);
        addHighlightedBy($otherTable, by);
        $otherTable.addClass('related-table').removeClass('faded');
    });

    if($doc.find('.node.related-table').size()) {
        $doc.find('.node:not(.related-table):not(.hovered):not(mouseover):not(.unwanted)').addClass('faded');
    }
}
function isKey(event, wantedKey) {
    return wantedKey.charCodeAt() === event.keyCode;
}
function allParams() {
    var queryString = {};
    location.search.substr(1)
                   .split('&')
                   .filter(string => string.length)
                   .map(qs => qs.split('='))
                   .map(listOfPairs => queryString[listOfPairs[0]] = listOfPairs[1]);
    return queryString;
}
function param(key) {
    var params = allParams();
    return params[key];
}
function paramToQueryString(params) {
    if(undefined === params) {
        params = allParams();
    }

    return '?' + Object.keys(params).map(key => { return [key, params[key]].join('=') }).join('&');
}