/**
 * ReferenceIDoitObjects
 * Copyright (C) 2011-17 synetics GmbH, <https://i-doit.com/>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * @author Benjamin Heisig <bheisig@i-doit.org>
 * @author Leonard Fischer <lfischer@synetics.de>
 * @author Van Quyen Hoang <qhoang@synetics.de>
 * @copyright synetics GmbH
 * @license http://www.gnu.org/licenses/agpl.txt GNU Affero General Public License
 */

/** @module org/idoit/referenceidoitobjects */

/**
 * Create a ticket in relation to one or more i-doit objects.
 *
 * @class
 * @param {object} params - Options
 */
ReferenceIDoitObjects = function (params) {

    "use strict";

    /**
     * Selected objects (as jQuery object)
     *
     * @type {object}
     */
    this.objects = $(params.objects);

    /**
     * Selected comma-separated list of customers (as jQuery object)
     *
     * @type {object}
     */
    this.customers = $(params.customers);

    /**
     * Selected tenant (as jQuery object)
     *
     * @type {object}
     */
    this.tenant = $(params.tenant);

    /**
     * Ticket title (subject)
     *
     * @type {string}
     */
    this.ticketTitle = $(params.ticket.title).val();

    /**
     * Raw data for the view of all objects
     *
     * @type {object}
     */
    this.objectsData = {};

    /**
     * Raw data for the view of workplaces
     *
     * @type {object}
     */
    this.workplacesData = {};

    /**
     * Raw data for the view of linked devices
     *
     * @type {object}
     */
    this.devicesData = {};

    /**
     * Is the browser initialized?
     *
     * @type {bool} - Defaults to false.
     */
    this.initialized = false;

    /**
     * Data store (as jQuery object)
     *
     * @type {object}
     */
    this.dataStore = $('#dataStore');

    /**
     * Content div (as jQuery object)
     *
     * @type {object}
     */
    this.content = $('#idoitObjectBrowserContent');

    /**
     * Notice div (as jQuery object)
     *
     * @type {object}
     */
    this.notice = $('#idoitNotice');

    /**
     * Object type selector (as jQuery object)
     *
     * @type {object}
     */
    this.objectTypeSelector = $('#idoitObjectTypeSelector');

    /**
     * Loading sign (as jQuery object)
     *
     * @type {object}
     */
    this.loadingSign = $('#idoitLoadingSign');

    this.installedSoftware = $('#idoitInstalledSoftware');

    /**
     * l10n for jQuery plugin data table
     *
     * @type {object}
     */
    this.dataTableL10N = {
        "sProcessing": params.l10n['Loading...'],
        "sLengthMenu": params.l10n['Show _MENU_ objects'],
        "sZeroRecords": params.l10n['No objects has been selected yet.'],
        "sInfo": params.l10n['_START_ to _END_ of _TOTAL_ objects'],
        "sInfoEmpty": params.l10n['0 to 0 of 0 objects'],
        "sInfoFiltered": params.l10n['(filtered from _MAX_ objects)'],
        "sInfoPostFix": "",
        "sSearch": params.l10n['Filter'],
        "sUrl": "",
        "oPaginate": {
            "sFirst": "&laquo;",
            "sPrevious": "&lsaquo;",
            "sNext": "&rsaquo;",
            "sLast": "&raquo;"
        }
    };

    /**
     * Table for objects (as data table)
     *
     * @type {object}
     */
    this.objectTable = $('#idoitAllObjectsTable').DataTable({
        "bJQueryUI": true,
        "bAutoWidth": false,
        "bLengthChange": false,
        "iDisplayLength": 20,
        "sPaginationType": "full_numbers",
        "oLanguage": this.dataTableL10N,
        "columns": [
            {"orderable": false},
            null,
            null,
            {"orderable": false}
        ],
        // Workaround because of doubled sorting icons in table head:
        "renderer": {
            "header": "bootstrap",
            "pageButton": "jqueryui"
        }
    });

    /**
     * Table for selected objects (as data table)
     *
     * @type {object}
     */
    this.selectedObjectsTable = $('#idoitSelectedObjectsTable').DataTable({
        "bJQueryUI": true,
        "bAutoWidth": false,
        "bPaginate": false,
        "bLengthChange": false,
        "oLanguage": this.dataTableL10N,
        "columns": [
            {"orderable": false},
            null,
            null,
            null,
            {"orderable": false}
        ],
        // Workaround because of doubled sorting icons in table head:
        "renderer": {
            "header": "bootstrap",
            "pageButton": "jqueryui"
        }
    });

    /**
     * Table for linked devices (as data table)
     *
     * @type {object}
     */
    this.devicesTable = $('#idoitDevicesTable').DataTable({
        "bJQueryUI": true,
        "bAutoWidth": false,
        "bLengthChange": false,
        "iDisplayLength": 20,
        "sPaginationType": "full_numbers",
        "oLanguage": this.dataTableL10N,
        "columns": [
            {"orderable": false},
            null,
            null,
            null,
            null,
            {"orderable": false},
            {"orderable": false}
        ],
        // Workaround because of doubled sorting icons in table head:
        "renderer": {
            "header": "bootstrap",
            "pageButton": "jqueryui"
        }
    });

    /**
     * Table for installed applications (as data table)
     *
     * @type {object}
     */
    this.installedApplicationTable = $('#idoitInstalledSoftwareTable').DataTable({
        "bJQueryUI": true,
        "bAutoWidth": false,
        "bLengthChange": false,
        "iDisplayLength": 20,
        "sPaginationType": "full_numbers",
        "oLanguage": this.dataTableL10N,
        "columns": [
            {"orderable": false},
            null,
            null,
            null,
            {"orderable": false}
        ],
        // Workaround because of doubled sorting icons in table head:
        "renderer": {
            "header": "bootstrap",
            "pageButton": "jqueryui"
        }
    });

    /**
     * Make this object available in sub methods:
     */
    var that = this;

    /***********************************************************************************************
     * Methods
     **********************************************************************************************/

    /**
     * Initializes the object browser.
     */
    this.init = function () {
        var data = {
            "method": "cmdb.object_types",
            "params": {
                "order_by": "title",
                "filter": {
                    "enabled":"true"
                }
            }
        };

        that.showNotice(params.l10n['Loading...']);

        // Initialize the data object.
        that.dataStore.data();

        that.callIDoit(data, function (response) {
            if (response !== null && response.error === undefined) {
                // Initialize the tabs.
                that.content.tabs({active: params.defaultView});

                // Check whether the preselection field is filled out.
                that.loadPreselectedData();

                // Load the customer data (workplaces and assigned objects).
                that.loadCustomerData();

                that.notice.css({display: 'none'});
                that.content.css({display: 'block'});

                that.objectTypeSelector.html('');
                $.each(response.result, function(i, e) {
                    $('<option value="' + e.id + '">' + e.title + '</option>')
                        .appendTo('#idoitObjectTypeSelector');
                });

                // Trigger the event.
                that.objectTypeSelector.change();

                // Activate chosen jQuery plugin:
                $(".chosen-select").chosen({
                    disable_search_threshold: 10,
                    no_results_text: params.l10n['Nothing found.'],
                    width: "264px"
                });

                that.initialized = true;
            } else {
                that.showNotice(params.l10n['Error while loading object types']);

                that.initialized = false;
            } //if
        }, true);
    }; //function

    /**
     * Loads and displays data of the customer (workplace, assigned objects, ...).
     */
    this.loadCustomerData = function () {
        var customers = [],
            customerList = that.customers.val(),
            workplacesInfo = $('#idoitWorkplacesTab div'),
            devicesInfo = $('#idoitDevicesInfo'),
            devicesTableWrapper = $('#idoitDevicesTable_wrapper');

        if (typeof customerList !== 'string' || customerList.length === 0) {
            workplacesInfo.html(params.l10n['There is no customer selected.']);
            $('#idoitDevicesInfo').html(params.l10n['There is no customer selected.']);
            devicesTableWrapper.hide();
            that.installedSoftware.hide();
            return;
        } //if

        workplacesInfo.html('');
        devicesInfo.html('');
        devicesTableWrapper.show();

        customers = customerList.replace(/(\s)/g, '').split(',');

        if (typeof customers !== 'undefined' && customers.length > 0) {
                that.showLoadingSign();
                that.loadWorkplaces(customers);
                that.loadDevices(customers);
        } //if
    }; //function

    /**
     * Fetches and displays all objects which are assigned in i-doit to the customer.
     *
     * @param {array} customers - List of customer e-mail addresses
     */
    this.loadWorkplaces = function (customers) {
        var data = {
            "method": "cmdb.workstation_components",
            "params": {
                "filter": {
                    "emails": customers
                }
            }
        };

        that.callIDoit(data, function (response) {
            that.hideLoadingSign();

            if (response.error === undefined) {
                that.workplacesData = response.result;
                that.renderWorkplacesView();
            } else {
                that.showNotice(params.l10n['Error while loading objects by email']);
            } //if
        }, true);
    }; //function

    /**
     * Fetches and displays all objects which are assigned in i-doit to the customer.
     *
     * @param {array} customers - List of customer e-mail addresses
     */
    this.loadDevices = function (customers) {
        var data = {
            "method": "cmdb.contact",
            "params": {
                "filter": {
                    "email": customers[0]
                },
                "method": "assigned_objects_by_contact"
            }
        };

        that.callIDoit(data, function (response) {
            that.hideLoadingSign();

            if (response.error === undefined) {
                that.devicesData = response.result;
                that.renderDevicesView();
            } else {
                that.showNotice(params.l10n['Error while loading objects by email']);
            } //if
        }, true);
    }; //function

    /**
     * Loads and displays preselected objects
     */
    this.loadPreselectedData = function () {
        var preselection = that.objects.val(),
            data = {};

        if (typeof preselection !== 'undefined') {
            switch (params.type) {
                case 'otrs':
                    // This DynamicField is an input text with a comma-separated list if object
                    // idenfiers:
                    preselection = preselection.replace(/^,/, '').replace(/,$/, '').split(",");
                    break;
                case 'rt':
                    // This CustomField is a textarea with one object identifer per line:
                    preselection = preselection.split("\n");
                    break;
            } //switch/case

            if (preselection !== '') {
                preselection = preselection.map(function (i) {
                    i = parseInt(i, 10);
                    return (!isNaN(i) ? i : 0);
                });

                if (preselection.length > 0) {
                    that.showLoadingSign();
                    // We first request the preselected ID's so we can display them correctly inside
                    // the "selected objects" list (ID, Name, Type).
                    data = {
                        "method": "cmdb.objects",
                        "params": {
                            "filter": {
                                "ids": preselection
                            }
                        }
                    };

                    that.callIDoit(data, function (response) {
                        that.hideLoadingSign();
                        if (response.error === undefined) {
                            that.removeAllObjects();

                            $.each(response.result, function (i, e) {
                                that.addObject(e.id, e.title, e.type_title);
                            });
                        } else {
                            that.showNotice(
                                params.l10n['Error while loading pre-selected objects']
                            );
                        }
                    }, true);
                } //if
            } //if
        } //if
    }; //function

    /**
     * Renews the view of workplaces.
     */
    this.renderWorkplacesView = function () {
        var workplaces;

        $('#idoitWorkplacesTab div').html('');

        if (that.workplacesData.length === 0) {
            $('#idoitWorkplacesTab div').html(
                params.l10n['Given customer(s) could not be found in i-doit.']
            );
        } //if

        workplaces = $('#idoitWorkplacesTab div.workplaces');

        // We iterate through the first level (email addresses).
        $.each(that.workplacesData, function (i, e) {
            workplaces.append(
                '<a href="' + params.url + '?objID=' + i +
                '" id="linkToPerson" target="_blank" style="font-weight:bold;">' + e.data.title +
                ' &lt;' + e.data.email + '&gt;</a><br />'
            );

            if (e.children !== false) {
                that.renderSubTree(e.children, 1);
            }

            workplaces.append('<br />');
        }); //each

        $('#idoitDevicesInfo').html($('#linkToPerson').clone());
    }; //function

    /**
     * Renews sub trees for the view of workplaces recursively.
     *
     * @param {array} data - Data from the parents' "children" array
     * @param {int} level - Identify how "deep" we are inside recursion and display it with
     * "level * 20px" margin.
     */
    this.renderSubTree = function (data, level) {
        $.each(data, function (i, e) {
            var selected = false;

            if (typeof that.dataStore.data(i) !== 'undefined') {
                selected = true;
            } //if

            $('#idoitWorkplacesTab div.workplaces').append(
                '<div><input type="checkbox" value="' + i +
                '" name="idoitWorkplacesObject[]" ' + ((selected) ? 'checked="checked"' : '') +
                ' style="margin-left:' + (level * 20) + 'px;"> ' +
                '<span class="obj-name"><a href="' + params.url + '?objID=' + i +
                '" target="_blank">' + e.data.title + '</a></span>' +
                ' (<span class="obj-type">' + e.data.type_title + '</span>) &raquo; ' +
                '<span class="relation-button">' + params.l10n['show installed software'] +
                '</span></div>'
            );

            if (e.children !== false) {
                that.renderSubTree(e.children, (level + 1));
            } //if
        });
    }; //function

    /**
     * Renders the view of linked devices.
     */
    this.renderDevicesView = function () {
        var devices = [];

        that.devicesTable
            .clear()
            .order([1, 'asc'])
            .draw();

        if (typeof that.devicesData !== 'object' ||
            Object.keys(that.devicesData).length === 0 ||
            that.devicesData.length === 0) {
            $('#idoitDevicesInfo').html(
                params.l10n['There are no roles defined for given customer(s).']
            );
        } else {
            $.each(that.devicesData, function (i, e) {
                var selected = false,
                    check = '',
                    link = '',
                    showSoftware = '';

                if (typeof that.dataStore.data(e.id) !== 'undefined') {
                    selected = true;
                }

                check = '<input type="checkbox" value="' + e.id +
                    '" name="idoitDevicesObject[]" ' + ((selected) ? 'checked="checked"' : '') +
                    ' />';

                link = '<a href="' + params.url + '?objID=' + e.id + '" target="_blank" title="' +
                    params.l10n['Go to i-doit'] + '">&raquo; i-doit</a>';

                showSoftware =
                    '<span class="installed-apps-button"><a href="javascript:void(null);" title="' +
                    params.l10n['show installed software'] +
                    '" onclick="referenceIDoitObjects.renderInstalledApplicationTable(' +
                    e.id + ', \'' + e.title + '\');">&raquo; ' +  params.l10n['Show'] +
                    '</a></span>';

                devices.push([
                    check,
                    e.id,
                    e.title,
                    e.type_title,
                    e.role,
                    showSoftware,
                    link
                ]);
            });

            that.devicesTable
                .rows.add(devices)
                .draw();
        } //if
    }; //function

    /**
     * Renders the table for installed applications for a specific object.
     *
     * @param {int} id - Object identifier
     * @param {string} title - Object title
     */
    this.renderInstalledApplicationTable = function (id, title) {
        var data = {};

        that.installedApplicationTable
            .clear()
            .order([1, 'asc'])
            .draw();

        if (id === undefined) {
            that.installedSoftware.hide();
            return;
        } //if

        $('#idoitInstalledSoftwareInfo span').html(
            '<a href="' + params.url + '?objID=' + id + '" title="' +
            params.l10n['Go to i-doit'] + '" target="_blank">' + title + '</a>'
        );

        if (params.installedSoftware === 'objects') {
            data = {
                "method": "cmdb.category",
                "params": {
                    "objID": id,
                    "catgID": "C__CATG__APPLICATION"
                }
            };
        } else {
            data = {
                "method": "cmdb.objects_by_relation",
                "params": {
                    "id": id,
                    "relation_type": "C__RELATION_TYPE__SOFTWARE"
                }
            };
        } //if

        that.callIDoit(data, function (response) {
            var applications = [],
                assignedApplicationsData = response.result;

            if (response.error === undefined) {
                that.installedSoftware.show();

                if (params.installedSoftware == 'objects') {
                    $.each(assignedApplicationsData, function (i, e) {
                        var selected = false,
                            check = '',
                            link = '';

                        if (typeof that.dataStore.data(e.application.id) !== 'undefined') {
                            selected = true;
                        } //if

                        check = '<input type="checkbox" value="' + e.application.id +
                            '" name="idoitInstalledApplicationsObject[]" ' +
                            ((selected) ? 'checked="checked"' : '') +
                            ' onchange="referenceIDoitObjects.checkCHKB(this)" />';
                        link = '<a href="' + params.url + '?objID=' + e.application.id +
                            '" target="_blank" title="' + params.l10n['Go to i-doit'] +
                            '">&raquo; i-doit</a>';

                        applications.push([
                            check,
                            e.application.id,
                            e.application.title,
                            e.application.type_title,
                            link
                        ]);
                    });
                } else {
                    $.each(assignedApplicationsData, function (i, e) {
                        var check,
                            selected = false,
                            link;

                        if (typeof that.dataStore.data(e.data.id) !== 'undefined') {
                            selected = true;
                        } //if

                        check = '<input type="checkbox"  value="' + e.data.id +
                            '" name="idoitInstalledApplicationsObject[]" ' +
                            ((selected) ? 'checked="checked"' : '') +
                            ' onchange="referenceIDoitObjects.checkCHKB(this)" />';
                        link = '<a href="' + params.url + '?objID=' + e.data.id +
                            '" target="_blank" title="' + params.l10n['Go to i-doit'] +
                            '">&raquo; i-doit</a>';

                        applications.push([
                            check,
                            e.data.id,
                            e.data.title,
                            e.data.related_type_title,
                            link
                        ]);
                    });
                } //if

                that.installedApplicationTable
                    .rows.add(applications)
                    .draw();
            } else {
                that.showNotice(params.l10n['Error while loading objects by email']);
            } //if
        }, true);
    }; //function

    /**
     * Renders object location tree. If too long tree will be trimmed.
     *
     * @param {array} tree Location tree
     */
    this.renderLocationTree = function (tree) {
        if (tree.length > 0) {
            // Trim location tree:
            if (tree.length > 3) {
                tree = [tree[0], '&hellip;', tree.slice(-1)];
            }

            return tree.join(' &raquo; ');
        } //if

        return '&ndash;';
    }; //function

    /**
     * Renews the view of all objects.
     */
    this.renderObjectsView = function () {
        var entities = [];

        that.objectTable
            .clear()
            .order([1, 'asc'])
            .draw();

        $.each(that.objectsData, function (i, e) {
            var selected = false,
                check = '',
                link = '';

            if (typeof that.dataStore.data(e.id) !== 'undefined') {
                selected = true;
            } //if

            check = '<input type="checkbox" value="' + e.id + '" name="idoitAllObjectsObject[]" ' +
                ((selected) ? 'checked="checked"' : '') + ' />';
            link = '<a href="' + params.url + '?objID=' + e.id + '" target="_blank" title="' +
                params.l10n['Go to i-doit'] + '">&raquo; i-doit</a>';

            entities.push([check, e.id, e.title, link]);
        });

        if (entities.length > 0) {
            that.objectTable
                .rows.add(entities)
                .draw();
        } //if
    }; //function

    /**
     * Renews view of selected objects. Will be used when adding or removing an object.
     */
    this.renderSelectedObjects = function () {
        var data = [],
            entities = [],
            raw;

        that.selectedObjectsTable
            .clear()
            .order([1, 'asc'])
            .draw();

        raw = that.dataStore.data();

        $.each(raw, function (i, e) {
            var link = '<a href="' + params.url + '?objID=' + i + '" title="' +
                params.l10n['Go to i-doit'] + '">&raquo; i-doit</a>';

            entities.push([
                '<a href="javascript:void(null);" class="idoitObjectBrowserRemover" onclick="referenceIDoitObjects.removeObject(' +
                    i + ')">' + params.l10n['Clear'] + '</a>',
                i,
                e.name,
                e.type,
                link
            ]);

            data.push(i);
        });

        if (entities.length > 0) {
            that.selectedObjectsTable
                .rows.add(entities)
                .draw();
        } //if

        switch (params.type) {
            case 'otrs':
                // This DynamicField is an input text with a comma-separated list if object
                // idenfiers:
                that.objects.val(',' + data.join(',') + ',');
                break;
            case 'rt':
                // This CustomField is a textarea with one object identifer per line:
                that.objects.val(data.join("\n"));
                break;
        } //switch/case
    }; //function

    /**
     * Removes an object from the selected data.
     *
     * @param {int} id - Object identifier
     */
    this.removeObject = function (id) {
        that.dataStore.removeData(id);

        that.renderSelectedObjects();

        // Instead of rendering the lists again we can do something like this:
        $('input[name="idoitAllObjectsObject[]"][value="' + id + '"]').prop('checked', false);
        $('input[name="idoitWorkplacesObject[]"][value="' + id + '"]').prop('checked', false);
        $('input[name="idoitDevicesObject[]"][value="' + id + '"]').prop('checked', false);
        $('input[name="idoitInstalledApplicationsObject[]"][value="' + id + '"]').prop('checked', false);
    }; //function

    /**
     * Removes all objects from the selected data.
     */
    this.removeAllObjects = function () {
        that.dataStore.removeData();

        that.renderSelectedObjects();
        that.renderObjectsView();
        that.renderWorkplacesView();
        that.renderDevicesView();
        that.renderInstalledApplicationTable();
    }; //function

    /**
     * Adds object to the selected data.
     *
     * @param {int} id - Object identifier
     * @param {string} name - Object title
     * @param {int} type - Object type
     */
    this.addObject = function (id, name, type) {
        if (typeof that.dataStore.data(id) !== 'undefined') {
            // its already in data store
            return;
        } //if

        that.dataStore.data(id, {"name": name, "type": type});

        that.renderSelectedObjects();

        // Instead of re-rendering the tables this is faster:
        $('input[name="idoitAllObjectsObject[]"][value="' + id + '"]').prop('checked', true);
        $('input[name="idoitWorkplacesObject[]"][value="' + id + '"]').prop('checked', true);
        $('input[name="idoitDevicesObject[]"][value="' + id + '"]').prop('checked', true);
        $('input[name="idoitInstalledApplicationsObject[]"][value="' + id + '"]').prop('checked', true);
    }; //function

    /**
     * Logs added or removed objects.
     *
     * An AJAX request will be sent to i-doit to add a new logbook entry for new selected objects or
     * removed previous ones.
     *
     * @param {bool} edit - Was the ticket edited? Otherwise it's created.
     */
    this.logChangedObjects = function (edit) {
        var preselection = that.objects.val(),
            message,
            comment,
            data = {};

        if (typeof preselection !== 'undefined') {
            switch (params.type) {
                case 'otrs':
                    // This DynamicField is an input text with a comma-separated list if object
                    // idenfiers:
                    preselection = preselection.replace(/^,/, '').replace(/,$/, '').split(",");
                    break;
                case 'rt':
                    // This CustomField is a textarea with one object identifer per line:
                    preselection = preselection.split("\n");
                    break;
            } //switch/case

            if (preselection !== '') {
                preselection = preselection.map(function (i) {
                    i = parseInt(i, 10);
                    return (!isNaN(i) ? i : 0);
                });

                if (preselection.length > 0) {
                    that.showLoadingSign();

                    // Was ticket created or updated?
                    if (edit === true) {
                        message = params.l10n['Ticket was edited.'];
                        comment = params.ticket.id;
                    } else {
                        message = params.l10n['Ticket was created.'];
                    }

                    data = {
                        "method": "cmdb.logbook.create",
                        "params": {
                            "object_ids": preselection,
                            "message": message,
                            "source": "C__LOGBOOK_SOURCE__RT",
                            "comment": comment,
                            "description": that.ticketTitle
                        }
                    };

                    that.callIDoit(data, function (response) {
                        if (response.error !== undefined) {
                            that.showNotice(
                                params.l10n['Error while creating i-doit logbook entry']
                            );
                        } //if
                    }, false);
                } //if
            } //if
        } //if
    }; //function

    /**
     * Sends an AJAX request to i-doit.
     *
     * @param {object} data - Options in JSON format
     * @param {callback} callback - Callback fired after a successful requests
     * @param {bool} async - Send request asyncronously?
     */
    this.callIDoit = function (data, callback, async) {
        // Enhance data:
        data.id = '1';
        data.jsonrpc = '2.0';
        data.params = data.params || {};
        data.params.language = params.language;

        switch (params.type) {
            case 'otrs':
                data.params.apikey = that.tenant.val();
                break;
            case 'rt':
                data.params.apikey = params.tenantKeys[that.tenant.val()];
                break;
        } //switch/case

        $.ajax({
            "url": params.api,
            "data": JSON.stringify(data),
            "contentType": "application/json",
            "type": "POST",
            "dataType": "json",
            "success": callback,
            "async": async
        });
    }; //function

    /**
     * Displays a message.
     *
     * @param {string} msg - Message
     */
    this.showNotice = function (msg) {
        that.notice.html(msg).fadeIn(500);
        that.content.css({display: 'none'});
    }; //function

    /**
     * Displays the loading sign.
     */
    this.showLoadingSign = function () {
        that.loadingSign.stop().fadeTo(0, 1);
        that.content.stop().fadeTo(0, 0.3);
    }; //function

    /**
     * Hides the loading sign.
     */
    this.hideLoadingSign = function () {
        that.loadingSign.stop().fadeTo(300, 0);
        that.content.stop().fadeTo(300, 1);
    }; //function

    /**
     * Stores the added IDs from the object view.
     *
     * @param {object} ele - Element
     */
    this.checkCHKB = function (ele) {
        var name,
            type;

        if (ele.checked) {
            name = $(ele).closest('tr').find('td:eq(2)').text();
            type = $(ele).closest('tr').find('td:eq(3)').text();

            that.dataStore.data(ele.value, {"name": name, "type": type});
        } else {
            that.dataStore.removeData(ele.value);
        } //if

        that.renderSelectedObjects();
    }; //function

    /**
     * Will re-initialize the object browser if tenant is changed.
     */
    this.changeTenant = function () {
        var key = that.tenant.val();

        that.removeAllObjects();

        if (key === '') {
            that.showNotice(params.l10n['Please select an i-doit tenant.']);
        } else {
            that.init();
        } //if
    }; //function

    /***********************************************************************************************
     * Events
     **********************************************************************************************/

    /**
     * Will fetch and display objects if object type is changed.
     */
    that.objectTypeSelector.change(function () {
        var data = {
            "method": "cmdb.objects",
            "params": {
                "filter": {
                    "type": parseInt(this.value, 10)
                },
                "order_by": "title"
            }
        };

        that.showLoadingSign();

        that.callIDoit(data, function (response) {
            if (response.error === undefined) {
                that.hideLoadingSign();
                // Clear the table from our old entries.
                that.objectsData = response.result;
                that.renderObjectsView();
            } else {
                that.showNotice(params.l10n['Error while loading objects by object type']);
            } //if
        }, true);
    }); //event

    /**
     * Will add/remove objects from the selection list if object's checkbox is checked/unchecked.
     */
    that.content.on('change', 'input[name="idoitAllObjectsObject[]"]', function () {
        var id = $(this).val(),
            name,
            type;

        if (this.checked) {
            name = $(this).closest('tr').find('td:eq(2)').text();
            type = $('#idoitObjectTypeSelector option:selected').text();

            that.addObject(id, name, type);
        } else {
            that.removeObject(id);
        } //if
    }); //event

    /**
     * Will add/remove objects from the selection list if object's checkbox is checked/unchecked.
     */
    that.content.on('change', 'input[name="idoitDevicesObject[]"], input[name="idoitInstalledApplicationsObject[]"]', function () {
        var id = $(this).val(),
            name,
            type;

        if (this.checked) {
            name = $(this).closest('tr').find('td:eq(2)').text();
            type = $(this).closest('tr').find('td:eq(3)').text();

            that.addObject(id, name, type);
        } else {
            that.removeObject(id);
        } //if
    }); //event

    /**
     * This event will store the added IDs from the view of workplaces.
     */
    that.content.on('change', 'input[name="idoitWorkplacesObject[]"]', function () {
        var name,
            type;

        if (this.checked) {
            name = $(this).next().text();
            type = $(this).next().next().text();
            that.addObject($(this).val(), name, type);
        } else {
            that.removeObject($(this).val());
        } //if
    }); //event

    /**
     * Will fetch and display related software objects if button is clicked.
     */
    that.content.on('click', 'span.relation-button', function () {
        var id = $(this).prev().prev().prev().val(),
            data = {};

        that.showLoadingSign();

        $(this).remove();

        data = {
            "method": "cmdb.objects_by_relation",
            "params": {
                "id": id,
                "relation_type": "C__RELATION_TYPE__SOFTWARE"
            }
        };

        that.callIDoit(data, function (response) {
            var div = $(this).parent(),
                span = parseInt($(this).prev().prev().prev().css('margin-left'), 10);

            that.hideLoadingSign();

            if (response.error === undefined) {
                $.each(response.result, function (i, e) {
                    var selected = false;

                    if (typeof that.dataStore.data(e.data.id) !== 'undefined') {
                        selected = true;
                    } //if

                    div.append(
                        '<br /><input type="checkbox" style="margin-left:' +
                            (span + 20) +'px;" value="' + e.data.id +
                            '" name="idoitWorkplacesObject[]" ' +
                            ((selected) ? 'checked="checked"' : '') + '/> ' +
                            '<span class="obj-name"><a href="' + params.url +
                            '?objID=' + e.data.id +
                            '" target="_blank" title="' + params.l10n['Go to i-doit'] + '">' +
                            e.data.related_title +
                            '</a></span> (<span class="obj-type">' +
                            e.data.related_type_title + '</span>)'
                    );
                });
            } else {
                that.showNotice(params.l10n['Error while loading relation objects']);
            } //if
        }, true);
    }); //event

    /**
     * Will select/unselect all objects' checkboxes in all objects view if checkbox is marked/unmarked.
     */
    $('#idoitCheckAllObjects').click(function () {
        $('input[name="idoitAllObjectsObject[]"]').prop('checked', this.checked).change();
    }); //event

    /**
     * Will select/unselect all objects' checkboxes in devices view if checkbox is marked/unmarked.
     */
    $('#idoitCheckAllDevices').click(function () {
        $('input[name="idoitDevicesObject[]"]').prop('checked', this.checked).change();
    }); //event

    /**
     * Will select/unselect all checkboxes of installed applications if checkbox is marked/unmarked.
     */
    $('#idoitCheckAllApps').click(function () {
        $('input[name="idoitInstalledApplicationsObject[]"]').prop('checked', this.checked).change();
    }); //event

    /**
     * Will reload customer data if clicked.
     */
    $('#idoitCustomerReload').click(function () {
        that.loadCustomerData();
    }); //event

    /**
     * Will remove all objects if clicked.
     */
    $('#idoitRemoveAllObjects').click(function () {
        that.removeAllObjects();
    }); //event

    /**
     * Will change tenant if changed.
     */
    that.tenant.on('change', function () {
        that.changeTenant();
    }); //event

    /**
     * Reloads customers' data. This will be fired if a new costumer is being selected.
     */
    that.customers.change(function () {
        if (that.initialized === true) {
            window.setTimeout(function () {
                that.loadCustomerData();
            }, 100);
        } //if
    }); //event

    /**
     * Reloads pre-selection. This will be fired if pre-selection field is being changed.
     */
    that.objects.change(function () {
        if (that.initialized) {
            that.loadPreselectedData();
        } //if
    }); //event

    /**
     * Saves ticket subject. This will be fired if subject field is being changed.
     */
    $(params.ticket.title).change(function () {
        that.ticketTitle = $(params.ticket.title).val();
    }); //event

    /**
     * Identifies the right ticket mode and triggers logbook entries:
     */
    switch (params.type) {
        case 'otrs':
            this.formOTRSEdit = $('form[name="compose"]');

            if (this.formOTRSEdit.length > 0) {
                this.formOTRSEdit.submit(function (event) {
                    that.logChangedObjects(true);
                });
            } //if
            break;
        case 'rt':
            this.formRTCreate = $('form[name="TicketCreate"]');
            this.formRTModifyIDoitObjects = $('form[name="ModifyReferencedIDoitObjects"]');
            this.formRTModifyAll = $('form[name="TicketModifyAll"]');

            if (this.formRTCreate.length > 0) {
                this.formRTCreate.submit(function (event) {
                    that.logChangedObjects(false);
                });
            } else if (this.formRTModifyIDoitObjects.length > 0) {
                this.formRTModifyIDoitObjects.submit(function (event) {
                    that.logChangedObjects(true);
                });
            } else if (this.formRTModifyAll.length > 0) {
                this.formRTModifyAll.submit(function (event) {
                    that.logChangedObjects(true);
                });
            } //if
            break;
    } //switch/case

    /**
     * Initializes the object browser or displays a message.
     */
    if (that.tenant.val() === '') {
        // This is RT specific:
        that.tenant.val(
            $(params.tenant + ' option').filter(function () {
                return $(this).html() === params.defaultTenant;
            }).val()
        );

        that.tenant.change();
    } else {
        that.init();
    } //if

}; //class
