var tableau;

$(function() {
    if (!$('#panel-user').length) return;
    initialiseTabUser();
    $('#menuAddUser').on('click', function(event) {
        addUser();
    });

    // ────────────────────────────────────────────────
    // Form validation using validators.js
    // ────────────────────────────────────────────────
async function validateUserForm() {
    const form = document.getElementById('user-form');
    if (!form) {
        console.error("Form #user-form not found");
        return { valid: false, errors: [{ field: null, message: l("Form not found") }], data: {} };
    }

    // Collect raw data
    const formDataObj = Object.fromEntries(new FormData(form).entries());

    // Cleanup and conversions (trim all strings)
    Object.keys(formDataObj).forEach(key => {
        if (typeof formDataObj[key] === 'string') {
            formDataObj[key] = formDataObj[key].trim();
        }
    });

    // IMPORTANT: DO NOT REMOVE password_confirm here, we need it for verification

    // Validate via FondationValidators
    if (typeof window.FondationValidators === 'undefined' || typeof FondationValidators.validate !== 'function') {
        console.error("FondationValidators not loaded or invalid");
        return { valid: false, errors: [{ field: null, message: l("Validator not available") }], data: {} };
    }

    // Determine schema based on mode
    const isUpdate = formDataObj.id && formDataObj.id.trim() !== '';
    const schemaName = isUpdate ? 'UserUpdate' : 'UserCreate';

    // In create mode, remove id to avoid sending an empty string to the server
    if (!isUpdate) {
        delete formDataObj.id;
    }
    const result = FondationValidators.validate(schemaName, formDataObj);

    // Additional validation for password / confirm (only if password is filled)
    if (formDataObj.password) {
        const pw = formDataObj.password.trim();
        const confirm = (formDataObj.password_confirm || '').trim();

        if (pw && !confirm) {
            result.valid = false;
            result.errors.push(l("Please confirm the password"));
        } else if (pw && confirm && pw !== confirm) {
            result.valid = false;
            result.errors.push(l("Passwords do not match"));
        }
    }

    // NOW remove password_confirm from the data sent to the server
    delete formDataObj.password_confirm;

    // In update mode, remove empty password (means "don't change password")
    // Must be stripped BEFORE sending to avoid server-side minLength rejection
    if (isUpdate && (!formDataObj.password || formDataObj.password.trim() === '')) {
        delete formDataObj.password;
    }

    // Collect group assignments (provided by Fondation::Group::UI::Bootstrap)
    if (typeof collectGroupAssignments === 'function') {
        formDataObj.groups = collectGroupAssignments();
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
                $('#user-form').prepend(alert);
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
            const validation = await validateUserForm();
            if (!validation.valid) {
                displayValidationErrors(validation.errors);
                return;
            }

            const id = validation.data.id;
            const method = id ? 'PUT' : 'POST';
            const url = id ? `/api/user/${id}` : '/api/user';

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

            successBox(l("User saved successfully"));
            $('#user-form')[0].reset();
            $('#user-modal').modal('hide');
            $('#example').DataTable().ajax.reload(null, false);
        } catch (err) {
            console.error("Error saving:", err);
            alert(l("Error: ") + (err.message || l("Unknown error")));
        } finally {
            button.prop('disabled', false).text(l("Save"));
        }
    });
});

/**
 * Initialize the user table
 */
function initialiseTabUser() {
    $("#loading-icon").hide();
    $("#panel-user").show();

    tableau = $('#example').DataTable({
        "dom": "<'row'<'col-sm-4'l><'col-sm-4'B><'col-sm-4'f>>" + "<'row'<'col-sm-12'tr>>" + "<'row'<'col-sm-5'i><'col-sm-7'p>>",
        "buttons": ['copy', 'csv', 'excel'],
        "aLengthMenu": [[10,50,100,200,500,1000,-1], [10,50, 100, 200, 500, 1000, l("All")]],
        "iDisplayLength": 10,
        mark: true,
        fixedHeader: {
            header: true,
        },
        "search": {
            "regex": true,
        },
        "bPaginate": true,
        "bLengthChange": false,
        "bInfo": true,
        "ajax": {
            "url": "/api/user?with=groups",
            "dataSrc": function (json) {
                return json;
            },
            error: function (xhr, error, code) {
                alertBox(xhr.responseJSON.error.message);
            }
        },
        "columns": [
            { "data": "id" },
            { "data": "username" },
            { "data": "email" },
            {
                "data": "groups",
                "render": function (data, type, row) {
                    if (!data || !data.length) return '';
                    var aff = '<ul>';
                    for (var i = 0; i < data.length; i++) {
                        aff += '<li>';
                        if (!data[i].active) { aff += '<del>'; }
                        aff += data[i].name;
                        if (!data[i].active) { aff += '</del>'; }
                        aff += '</li>';
                    }
                    aff += '</ul>';
                    return aff;
                }
            },
            {
                "data": "active",
                "render": function (data, type, row) {
                    if (type === 'display') {
                        return data == 1
                            ? '<span class="badge bg-success">' + l("Active") + '</span>'
                            : '<span class="badge bg-secondary">' + l("Inactive") + '</span>';
                    }
                    return data;
                },
                "width": "8%",
            },
            {
                "data": null,
                "render": function (data, type, row) {
                    if (type === 'display') {
                        if (row.active == 1) {
                            return renderActions([
                                { 'perm': 'user_update', 'title': l('Edit user'), 'classe': "fa fa-edit intModifie" },
                                { 'perm': 'user_delete', 'title': l('Delete user'), 'classe': "fa fa-trash intSupprime" },
                                { 'perm': 'user_update', 'title': l('Make inactive'), 'classe': "fa fa-times intInactive" },
                            ]);
                        } else {
                            return renderActions([
                                { 'perm': 'user_update', 'title': l('Edit user'), 'classe': "fa fa-edit intModifie" },
                                { 'perm': 'user_delete', 'title': l('Delete user'), 'classe': "fa fa-trash intSupprime" },
                                { 'perm': 'user_update', 'title': l('Make active'), 'classe': "fa fa-check intActive" }
                            ]);
                        }
                    }
                    return data;
                },
                "className": 'nowrap details-control',
                "orderable": false,
                "data": null,
                "width": "10%",
            },
        ],
        "fnRowCallback": function (nRow, aData, iDisplayIndex, iDisplayIndexFull) {
            if (aData['active'] == 0) {
                $('td', nRow).css('background-color', '#CCC');
            }
        },
        "initComplete": function(settings, json) {
            var hasGroups = false;
            for (var i = 0; i < json.length; i++) {
                if (json[i].groups) {
                    hasGroups = true;
                    break;
                }
            }
            if (!hasGroups) {
                this.api().column(3).visible(false);
            }
        },
        "order": [[ 1, "asc" ]]
    });

    // Bindings for actions
    $('#example tbody').on('click', 'span.intSupprime', function () {
        var row = tableau.row($(this).closest("tr"));
        var idUser = row.data().id;
        var nomUser = row.data().username;
        $('#confirmDeleteUser').modal("show");
        $('#confirmDeleteUser')
            .modal({ backdrop: 'static', keyboard: false })
            .one('click', '#deleteInt', function (e) {
                deleteUser(idUser, nomUser);
                $('#confirmDeleteUser').modal("hide");
            });
    });

    $('#example tbody').on('click', 'span.intModifie', function () {
        loadUser(tableau.row($(this).closest("tr")).data().id);
    });

    $('#example tbody').on('dblclick', 'td', function () {
        loadUser(tableau.row($(this).closest("tr")).data().id);
    });

    $('#example tbody').on('click', 'span.intInactive', function () {
        var row = tableau.row($(this).closest("tr"));
        var idUser = row.data().id;
        var nomUser = row.data().username;
        $('.nom_user').text(nomUser);
        $('#confirmDeactivateUser').modal("show");
        $('#confirmDeactivateUser')
            .modal({ backdrop: 'static', keyboard: false })
            .one('click', '#inactiveInt', function (e) {
                toggleActive(idUser, 0);
                $('#confirmDeactivateUser').modal("hide");
            });
    });

    $('#example tbody').on('click', 'span.intActive', function () {
        var row = tableau.row($(this).closest("tr"));
        var idUser = row.data().id;
        var nomUser = row.data().username;
        $('.nom_user').text(nomUser);
        $('#confirmActivateUser').modal("show");
        $('#confirmActivateUser')
            .modal({ backdrop: 'static', keyboard: false })
            .one('click', '#activeInt', function (e) {
                toggleActive(idUser, 1);
                $('#confirmActivateUser').modal("hide");
            });
    });
}

/**
 * Open the modal in create mode (add)
 */
function addUser() {
    clearModal();
    $('#user-modal .modal-title').text(l('Add user'));
    $('#password-group, #password-confirm-group').show();
    $('#user-modal').modal('show');

    if (typeof loadGroups === 'function') {
        loadGroups(null);
    }
}

/**
 * Load user data and open the modal in edit mode
 * @param {number} id - User ID
 */
function loadUser(id) {
    $('body').css('cursor', 'progress');

    $.getJSON('/api/user/' + id + '?with=groups', function(user) {
        clearModal();
        $('#user-modal .modal-title').text(l('Update user'));
        $('#password-group, #password-confirm-group').hide(); // hidden in edit mode
        $('#id').val(user.id);
        $('#username').val(user.username);
        $('#email').val(user.email);

        if (typeof loadGroups === 'function') {
            loadGroups(user);
        }

        $('body').css('cursor', '');
        $('#user-modal').modal('show');
    }).fail(function() {
        alert(l('Error loading user'));
        $('body').css('cursor', '');
    });
}

/**
 * Clear and reset the form
 */
function clearModal() {
    $('#id').val('');
    $('#username').val('');
    $('#password').val('');
    $('#password_confirm').val('');
    $('#email').val('');
    $('#password-group, #password-confirm-group').hide();
}

/**
 * Delete a user
 * @param {number} idUser - User ID
 * @param {string} nomUser - Name for display
 */
function deleteUser(idUser, nomUser) {
    $.ajax({
        type: 'DELETE',
        url: '/api/user/' + idUser,
    }).done(function(data) {
        $('#example').DataTable().ajax.reload(null, false);
        successBox(l("Delete user") + " '" + nomUser + "' OK");
    }).fail(function(xhr) {
        alertBox(l("Deletion failed") + "<br/><br/>" + (xhr.responseJSON?.error?.message || l("Unknown error")));
    });
}

/**
 * Toggle a user's active status via PATCH /api/user/{id}
 * @param {number} idUser - User ID
 * @param {number} active - 0 to deactivate, 1 to activate
 */
function toggleActive(idUser, active) {
    $.ajax({
        type: 'PATCH',
        url: '/api/user/' + idUser,
        contentType: 'application/json',
        data: JSON.stringify({ active: active }),
    }).done(function(data) {
        $('#example').DataTable().ajax.reload(null, false);
        var msg = active ? l("activated") : l("deactivated");
        successBox(l("User") + " " + msg);
    }).fail(function(xhr) {
        alertBox(l("Operation failed") + "<br/><br/>" + (xhr.responseJSON?.error?.message || l("Unknown error")));
    });
}
