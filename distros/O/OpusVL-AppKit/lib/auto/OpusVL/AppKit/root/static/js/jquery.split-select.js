// Splits either a multiple select box or multiple checkboxes into two selects.
// If multiple checkboxes are provided, give the container, since the names
// for the new selects will come from the labels.

(function($) {
    function SplitSelect($element) {
        var $activeSet = $('<select/>'),
            $inactiveSet = $('<select/>'),
            $activateThese = $('<button/>'),
            $activateAll = $('<button/>'),
            $deactivateThese = $('<button/>'),
            $deactivateAll = $('<button/>'),
            name = getNameFrom($element),
            statusQuo = createOptionSets($element);

        $activeSet.attr({
           'multiple': true,
           'class': 'js-split-select-active',
           'name': name,
           'id': name + '-active'
        });

        $inactiveSet.attr({
           'multiple': true,
           'class': 'js-split-select-inactive',
           'name': name + '-inactive',
           'id': name + '-inactive'
        });

        $inactiveSet
            .on('dblclick', function(e) {
                $(this)
                    .find('option:selected')
                    .attr('selected', false)
                    .appendTo($activeSet);
                sort($activeSet);
            });

        $activeSet
            .on('dblclick', function(e) {
                $(this)
                    .find('option:selected')
                    .attr('selected', false)
                    .appendTo($inactiveSet);
                sort($inactiveSet);
            });

        $activateThese
            .html('>')
            .on('click', function(e) {
                $inactiveSet.find(':selected')
                    .attr('selected', false)
                    .appendTo($activeSet);
                sort($activeSet);
                e.preventDefault();
            });

        $activateAll
            .html('>>')
            .on('click', function(e) {
                $inactiveSet.find('option')
                    .attr('selected', false)
                    .appendTo($activeSet);
                sort($activeSet);
                e.preventDefault();
            });

        $deactivateThese
            .html('<')
            .on('click', function(e) {
                $activeSet.find(':selected')
                    .attr('selected', false)
                    .appendTo($inactiveSet);
                sort($inactiveSet);
                e.preventDefault();
            });

        $deactivateAll
            .html('<<')
            .on('click', function(e) {
                $activeSet.find('option')
                    .attr('selected', false)
                    .appendTo($inactiveSet);
                sort($inactiveSet);
                e.preventDefault();
            });

        $element.closest('form').on('submit', function() {
            // Select everything so it's actually posted
            $activeSet.find('option').attr('selected', true);
        });

        console.log(statusQuo);
        $activeSet.append(statusQuo[0]);
        $inactiveSet.append(statusQuo[1]);

        $element.children().not('fieldset').remove();
        $element
            .append($inactiveSet)
            .append($('<div/>')
                .addClass('split-select-controls')
                .append($activateAll)
                .append($activateThese)
                .append($deactivateThese)
                .append($deactivateAll)
            )
            .append($activeSet);
    }

    function sort($e) {
        $e.sortBy(function(a) {
            return a.data('sort-order');
        });
    }

    function createOptionSets($input) {
        var active = [],
            inactive = [],
            $option = $('<option/>');

        $input = $input.find(':input');

        if ($input.is('select')) {
            $input.find('option').each(function(index) {
                var $this = $(this),
                    $newOpt = $option.clone();

                $newOpt.attr('value', $this.value);
                $newOpt.html($this.html());

                $newOpt.data('sort-order', index);
                
                // TODO: optgroups
                if ($this.is(':selected')) {
                    active.push($newOpt);
                }
                else {
                    inactive.push($newOpt);
                }
            });
        }
        else {
            $input.each(function(index) {
                var $actualInput = $(this),
                    $container = $actualInput.closest(':has(label)'),
                    $newOpt = $option.clone();

                $newOpt.attr('value', $actualInput.val());
                $newOpt.html($container.find('label').html());

                $newOpt.data('sort-order', index);

                if ($actualInput.is(':checked')) {
                    active.push($newOpt);
                }
                else {
                    inactive.push($newOpt);
                }
            });
        }

        return [ active, inactive ];
    }
    
    function getNameFrom($container) {
        return $container.find('input')[0].name;
    }

    $.fn.splitSelect = function() {
        var $elem = $(this);

        if ($elem.is(':input')) {
            $elem = $elem.closest(':has(:input)');
        }

        var ss = new SplitSelect($elem);

        $elem.data('split-select', ss);

        return $elem;
    }

})(jQuery);
