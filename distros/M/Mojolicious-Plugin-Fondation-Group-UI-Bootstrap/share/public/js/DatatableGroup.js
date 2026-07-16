var tableau;

$(function() {
    if (!$('#panel-group').length) return;
    initialiseTabGroup();
    $('#menuAddGroup').on('click', function(event) {
        addGroup();
    });

    // ────────────────────────────────────────────────
    // Form validation using validators.js
    // ────────────────────────────────────────────────
    async function validateGroupForm() {
        const form = document.getElementById('group-form');
        if (!form) {
            console.error("Form #group-form not found");
            return { valid: false, errors: [{ field: null, message: l("Form not found") }], data: {} };
        }

        const formDataObj = Object.fromEntries(new FormData(form).entries());

        // Cleanup (trim all strings)
        Object.keys(formDataObj).forEach(key => {
            if (typeof formDataObj[key] === 'string') {
                formDataObj[key] = formDataObj[key].trim();
            }
        });

        // Validate via FondationValidators
        if (typeof window.FondationValidators === 'undefined' || typeof FondationValidators.validate !== 'function') {
            console.error("FondationValidators not loaded or invalid");
            return { valid: false, errors: [{ field: null, message: l("Validator not available") }], data: {} };
        }

        const schemaName = 'Group';

        const result = FondationValidators.validate(schemaName, formDataObj);

        // Collect perm assignments (provided by Fondation::Perm::UI::Bootstrap)
        if (typeof collectPermAssignments === 'function') {
            formDataObj.perms = collectPermAssignments();
        }

        return {
            valid: result.valid,
            errors: result.errors.map(msg => ({
                field: null,
                message: msg
            })),
            data: formDataObj
        };
    }

    // Display errors (Bootstrap 5 style)
    function displayValidationErrors(errors) {
        $('.is-invalid').removeClass('is-invalid');
        $('.invalid-feedback').remove();

        errors.forEach(err => {
            let input = err.field ? document.getElementById(err.field) : null;

            if (!input) {
                const alert = $(`<div class="alert alert-danger mt-3">${err.message}</div>`);
                $('#group-form').prepend(alert);
                setTimeout(() => alert.fadeOut(3000), 8000);
                return;
            }

            input.classList.add('is-invalid');
            const feedback = document.createElement('div');
            feedback.className = 'invalid-feedback';
            feedback.textContent = err.message;
            input.parentNode.appendChild(feedback);
        });
    }

    // ────────────────────────────────────────────────
    // "Save" button
    // ────────────────────────────────────────────────
    $('#saveObject').on('click', async function() {
        const button = $(this);
        button.prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i> ' + l("Saving..."));

        try {
            const validation = await validateGroupForm();
            if (!validation.valid) {
                displayValidationErrors(validation.errors);
                return;
            }

            const id = validation.data.id;
            const method = id ? 'PUT' : 'POST';
            const url = id ? `/api/group/${id}` : '/api/group';

            // id is in the URL path, not the request body
            delete validation.data.id;

            const response = await fetch(url, {
                method,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(validation.data)
            });

            if (!response.ok) {
                const body = await response.json();
                // OpenAPI validation errors: {errors: [{message: "...", path: "..."}]}
                const msg = body?.errors?.map(e => e.message).join('; ')
                    || body?.message
                    || response.statusText;
                throw new Error(msg);
            }

            successBox(l("Group saved successfully"));
            $('#group-form')[0].reset();
            $('#group-modal').modal('hide');
            $('#table-group').DataTable().ajax.reload(null, false);
        } catch (err) {
            console.error("Error saving group:", err);
            alert(l("Error: ") + (err.message || l("Unknown error")));
        } finally {
            button.prop('disabled', false).text(l("Save"));
        }
    });
});

/**
 * Initialize the group table
 */
function initialiseTabGroup() {
    if (!$('#table-group').length) return;
    $("#loading-icon").hide();
    $("#panel-group").show();

    tableau = $('#table-group').DataTable({
        "dom": "<'row'<'col-sm-4'l><'col-sm-4'B><'col-sm-4'f>>" + "<'row'<'col-sm-12'tr>>" + "<'row'<'col-sm-5'i><'col-sm-7'p>>",
        "buttons": ['copy', 'csv', 'excel'],
        "aLengthMenu": [[10,50,100,200,500,1000,-1], [10,50, 100, 200, 500, 1000, l("All")]],
        "iDisplayLength": 10,
        mark: true,
        "search": {
            "regex": true,
        },
        "bPaginate": true,
        "bLengthChange": false,
        "bInfo": true,
        "ajax": {
            "url": "/api/group?with=perms",
            "dataSrc": function (json) {
                return json;
            },
            error: function (xhr, error, code) {
                console.error('Error loading groups:', xhr.responseJSON?.errors?.[0]?.message || error);
            }
        },
        "columns": [
            { "data": "name" },
            {
                "data": null,
                "render": function (data, type, row) {
                    var aff = '<ul>';
                    if (row.perms && row.perms.length > 0) {
                        for (var i = 0; i < row.perms.length; i++) {
                            aff += '<li>' + row.perms[i].name + '</li>';
                        }
                    }
                    aff += '</ul>';
                    return aff;
                }
            },
            {
                "data": null,
                "render": function (data, type, row) {
                    if (type === 'display') {
                        return renderActions([
                            { 'perm': 'group_update', 'title': l('Edit group'), 'classe': "fa fa-edit intModifie" },
                            { 'perm': 'group_delete', 'title': l('Delete group'), 'classe': "fa fa-trash intSupprime" },
                        ]);
                    }
                    return data;
                },
                "className": 'nowrap details-control',
                "orderable": false,
                "data": null,
                "width": "10%",
            },
        ],
        "order": [[ 0, "asc" ]],
        "initComplete": function(settings, json) {
            var hasPerms = false;
            for (var i = 0; i < json.length; i++) {
                if (json[i].perms && json[i].perms.length > 0) {
                    hasPerms = true;
                    break;
                }
            }
            if (!hasPerms) {
                this.api().column(1).visible(false);
            }
        }
    });

    // Bindings for actions
    $('#table-group tbody').on('click', 'span.intSupprime', function () {
        var row = tableau.row($(this).closest("tr"));
        var idGroup = row.data().id;
        var nomGroup = row.data().name;
        $('#confirmSuppressionGroup').modal("show");
        $('#confirmSuppressionGroup')
            .modal({ backdrop: 'static', keyboard: false })
            .one('click', '#deleteInt', function (e) {
                deleteGroup(idGroup, nomGroup);
                $('#confirmSuppressionGroup').modal("hide");
            });
    });

    $('#table-group tbody').on('click', 'span.intModifie', function () {
        loadGroup(tableau.row($(this).closest("tr")).data().id);
    });

    $('#table-group tbody').on('dblclick', 'td', function () {
        loadGroup(tableau.row($(this).closest("tr")).data().id);
    });
}

/**
 * Open the modal in create mode (add)
 */
function addGroup() {
    clearModal();
    $('#group-modal .modal-title').text(l('Add a group'));
    $('#group-modal').modal('show');

    // Populate perm checkboxes (none pre-checked)
    if (typeof loadPerms === 'function') {
        loadPerms(null);
    }
}

/**
 * Load group data and open the modal in edit mode
 * @param {number} id - Group ID
 */
function loadGroup(id) {
    $('body').css('cursor', 'progress');

    $.getJSON('/api/group/' + id + '?with=perms', function(group) {
        clearModal();
        $('#group-modal .modal-title').text(l('Edit group'));
        $('#id').val(group.id);
        $('#name').val(group.name);

        if (typeof loadPerms === 'function') {
            loadPerms(group);
        }

        $('body').css('cursor', '');
        $('#group-modal').modal('show');
    }).fail(function() {
        console.error('Error loading group');
        $('body').css('cursor', '');
    });
}

/**
 * Clear and reset the form
 */
function clearModal() {
    $('#id').val('');
    $('#name').val('');
}

/**
 * Delete a group
 * @param {number} idGroup - Group ID
 * @param {string} nomGroup - Name for display
 */
function deleteGroup(idGroup, nomGroup) {
    $.ajax({
        type: 'DELETE',
        url: '/api/group/' + idGroup,
    }).done(function(data) {
        $('#table-group').DataTable().ajax.reload(null, false);
        successBox(l("Delete group") + " '" + nomGroup + "' OK");
    }).fail(function(xhr) {
        alertBox(l("Deletion failed") + "<br/><br/>" + (xhr.responseJSON?.errors?.[0]?.message || l("Unknown error")));
    });
}
