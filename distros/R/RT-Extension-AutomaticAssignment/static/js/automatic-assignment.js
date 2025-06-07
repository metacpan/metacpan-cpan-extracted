htmx.onLoad(function (elt) {
    var form = jQuery(elt).find("#automatic-assignment");
    if (!form.length) {
        return;
    }

    var addFilterSelect = form.find('select[name=FilterType]');
    var filtersField = form.find('input[name=Filters]');
    var chooserField = form.find('input[name=Chooser]');
    var filterContainer = form.find('.filters');
    var chooserContainer = form.find('.chooser');
    var filterList = form.find('.filter-list');
    var filterListUl = filterList.find('ul');
    var addFilterButton = form.find('input[name=AddFilter]');

    var i = filterList.find('.sortable-box').length;
    var queueId = form.find('input[name=id]').val();

    var refreshFiltersField = function () {
        var filters = "";
        filterList.find('.sortable-box').each(function () {
            filters += jQuery(this).data('prefix') + ',';
        });

        filtersField.val(filters);
    };

    addFilterButton.click(function (e) {
        e.preventDefault();
        var filter = addFilterSelect.val();
        if (filter) {
            var params = {
                Name: filter,
                Queue: queueId,
                i: ++i
            };

            filterContainer.addClass('adding');
            addFilterSelect.attr('disabled', true);
            addFilterButton.attr('disabled', true);

            jQuery.ajax({
                url: RT.Config.WebHomePath + "/Helpers/AddFilter",
                data: params,
                success: function (html) {
                    var newElements = jQuery(html).prependTo(filterListUl).hide().slideDown();
                    RT.selectionBox.registerDrag(newElements[0]);
                    refreshFiltersField();
                    filterContainer.removeClass('adding');
                    addFilterSelect.val('').attr('disabled', false);
                    addFilterButton.attr('disabled', false);
                },
                error: function (xhr, reason) {
                    alert(reason);
                }
            });
        }
        else {
            alert("Please select a filter.");
        }
    });

    form.on('click', '.sortable-box .remove', function (e) {
        e.preventDefault();
        jQuery(this).closest('.sortable-box').slideUp(400, function () {
            jQuery(this).remove();
            refreshFiltersField();
        });
    });

    jQuery('.sortable-filter').each(function() {
        RT.selectionBox.registerDrag(this);
    });

    jQuery('.filter-list').each(function() {
        RT.selectionBox.registerDrop(this);
    });

    jQuery('.filter-list').on('dragend', function() {
       refreshFiltersField();
    });

});

