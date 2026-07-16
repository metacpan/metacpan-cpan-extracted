var tableau;

$(function() {
    if (!$('#panel-perm').length) return;
    initialiseTabPerm();
    $('#menuAddPerm').on('click', function(event) {
        addPerm();
    });

    // ────────────────────────────────────────────────
    // Form validation using validators.js
    // ────────────────────────────────────────────────
    async function validatePermForm() {
        const form = document.getElementById('perm-form');
        if (!form) {
            console.error("Form #perm-form not found");
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

        const schemaName = 'Perm';

        const result = FondationValidators.validate(schemaName, formDataObj);

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
                $('#perm-form').prepend(alert);
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
            const validation = await validatePermForm();
            if (!validation.valid) {
                displayValidationErrors(validation.errors);
                return;
            }

            const id = validation.data.id;
            const method = id ? 'PUT' : 'POST';
            const url = id ? `/api/perm/${id}` : '/api/perm';

            // id is in the URL path, not the request body
            delete validation.data.id;

            const response = await fetch(url, {
                method,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(validation.data)
            });

            if (!response.ok) {
                const body = await response.json();
                const msg = body?.errors?.map(e => e.message).join('; ')
                    || body?.message
                    || response.statusText;
                throw new Error(msg);
            }

            successBox(l("Permission saved successfully"));
            $('#perm-form')[0].reset();
            $('#perm-modal').modal('hide');
            $('#table-perm').DataTable().ajax.reload(null, false);
        } catch (err) {
            console.error("Error saving permission:", err);
            alert(l("Error: ") + (err.message || l("Unknown error")));
        } finally {
            button.prop('disabled', false).text(l("Save"));
        }
    });
});

/**
 * Initialize the permission table
 */
function initialiseTabPerm() {
    if (!$('#table-perm').length) return;
    $("#loading-icon").hide();
    $("#panel-perm").show();

    tableau = $('#table-perm').DataTable({
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
            "url": "/api/perm",
            "dataSrc": function (json) {
                return json;
            },
            error: function (xhr, error, code) {
                console.error('Error loading permissions:', xhr.responseJSON?.errors?.[0]?.message || error);
            }
        },
        "columns": [
            { "data": "name" },
            { "data": "description" },
            {
                "data": null,
                "render": function (data, type, row) {
                    if (type === 'display') {
                        return renderActions([
                            { 'perm': 'perm_update', 'title': l('Edit permission'), 'classe': "fa fa-edit intModifie" },
                            { 'perm': 'perm_delete', 'title': l('Delete permission'), 'classe': "fa fa-trash intSupprime" },
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
        "order": [[ 0, "asc" ]]
    });

    // Bindings for actions
    $('#table-perm tbody').on('click', 'span.intSupprime', function () {
        var row = tableau.row($(this).closest("tr"));
        var idPerm = row.data().id;
        var namePerm = row.data().name;
        $('#confirmDeletePerm').modal("show");
        $('#confirmDeletePerm')
            .modal({ backdrop: 'static', keyboard: false })
            .one('click', '#deleteInt', function (e) {
                deletePerm(idPerm, namePerm);
                $('#confirmDeletePerm').modal("hide");
            });
    });

    $('#table-perm tbody').on('click', 'span.intModifie', function () {
        loadPerm(tableau.row($(this).closest("tr")).data().id);
    });

    $('#table-perm tbody').on('dblclick', 'td', function () {
        loadPerm(tableau.row($(this).closest("tr")).data().id);
    });
}

/**
 * Open the modal in create mode (add)
 */
function addPerm() {
    clearModal();
    $('#perm-modal .modal-title').text(l('Add permission'));
    $('#perm-modal').modal('show');
}

/**
 * Load permission data and open the modal in edit mode
 * @param {number} id - Permission ID
 */
function loadPerm(id) {
    $('body').css('cursor', 'progress');

    $.getJSON('/api/perm/' + id, function(perm) {
        clearModal();
        $('#perm-modal .modal-title').text(l('Edit permission'));
        $('#id').val(perm.id);
        $('#name').val(perm.name);
        $('#description').val(perm.description);

        $('body').css('cursor', '');
        $('#perm-modal').modal('show');
    }).fail(function() {
        console.error('Error loading permission');
        $('body').css('cursor', '');
    });
}

/**
 * Clear and reset the form
 */
function clearModal() {
    $('#id').val('');
    $('#name').val('');
    $('#description').val('');
}

/**
 * Delete a permission
 * @param {number} idPerm - Permission ID
 * @param {string} namePerm - Name for display
 */
function deletePerm(idPerm, namePerm) {
    $.ajax({
        type: 'DELETE',
        url: '/api/perm/' + idPerm,
    }).done(function(data) {
        $('#table-perm').DataTable().ajax.reload(null, false);
        successBox(l("Delete permission") + " '" + namePerm + "' OK");
    }).fail(function(xhr) {
        alertBox(l("Deletion failed") + "<br/><br/>" + (xhr.responseJSON?.errors?.[0]?.message || l("Unknown error")));
    });
}
