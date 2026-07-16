// Menu admin JavaScript - modal add/edit/delete
(function () {
    'use strict';
    var editingId = null;

    window.add_child_menu = function (parentId, menuName) {
        editingId = null;
        document.getElementById('menu-form').reset();
        document.getElementById('id').value = '';
        document.getElementById('name').value = menuName || '';
        var sel = document.getElementById('parents');
        sel.value = parentId || '0';
        if (typeof $ !== 'undefined' && $.fn.selectpicker) { $('#parents').selectpicker('refresh'); }
        document.getElementById('menu-modal-title').textContent = l('Add a menu');
        document.getElementById('saveMenu').textContent = l('Save');
        new bootstrap.Modal(document.getElementById('menu-modal')).show();
    };

    window.edit_child_menu = function (parentId, menuName, id) {
        editingId = id;
        document.getElementById('menu-form').reset();
        fetch('/api/menu/' + id)
            .then(function (r) { if (!r.ok) throw new Error(r.statusText); return r.json(); })
            .then(function (menu) {
                document.getElementById('id').value           = menu.id || '';
                document.getElementById('name').value         = menu.name || '';
                document.getElementById('title').value        = menu.title || '';
                document.getElementById('link').value         = menu.link || '';
                document.getElementById('condition').value    = menu.condition || '';
                document.getElementById('icon').value         = menu.icon || '';
                document.getElementById('icon_color').value   = menu.icon_color || '#000000';
                document.getElementById('sort_order').value   = menu.sort_order || 0;
                var sel = document.getElementById('parents');
                sel.value = (menu.parent_id || 0).toString();
                if (typeof $ !== 'undefined' && $.fn.selectpicker) { $('#parents').selectpicker('refresh'); }
                document.getElementById('open_tab').checked   = menu.open_tab == 1;
                document.getElementById('view_in_menu').checked = menu.view_in_menu !== 0;
                document.getElementById('description').value  = menu.description || '';
                document.getElementById('menu-modal-title').textContent = l('Edit menu');
                document.getElementById('saveMenu').textContent = l('Update');
                new bootstrap.Modal(document.getElementById('menu-modal')).show();
            })
            .catch(function (err) { console.error('Failed to load menu:', err); });
    };

    window.delete_child_menu = function (id, title) {
        document.getElementById('deleteMenuId').value = id;
        document.getElementById('deleteMenuTitle').textContent = title;
        new bootstrap.Modal(document.getElementById('confirmDeleteMenu')).show();
    };

    document.getElementById('saveMenu').addEventListener('click', function () {
        var form = document.getElementById('menu-form');
        var formData = new FormData(form);
        var formDataObj = {};
        formData.forEach(function (v, k) { formDataObj[k] = v; });
        var isUpdate = !!editingId;
        var url = isUpdate ? '/api/menu/' + editingId : '/api/menu';
        var method = isUpdate ? 'PUT' : 'POST';
        delete formDataObj.id;
        if (!formDataObj.parents || formDataObj.parents === '') {
            formDataObj.parent_id = 0;
        } else {
            formDataObj.parent_id = parseInt(formDataObj.parents, 10) || 0;
        }
        delete formDataObj.parents;
        formDataObj.open_tab     = document.getElementById('open_tab').checked ? 1 : 0;
        formDataObj.view_in_menu = document.getElementById('view_in_menu').checked ? 1 : 0;
        formDataObj.sort_order = parseInt(formDataObj.sort_order, 10) || 0;
        fetch(url, {
            method: method,
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
            },
            body: JSON.stringify(formDataObj)
        })
        .then(function (r) {
            if (!r.ok) {
                return r.json().then(function (body) {
                    var msg = (body && body.errors ? body.errors.map(function (e) { return e.message; }).join('; ') : null)
                        || (body ? body.message : null) || r.statusText;
                    throw new Error(msg);
                });
            }
            return r.json();
        })
        .then(function () {
            bootstrap.Modal.getInstance(document.getElementById('menu-modal')).hide();
            window.location.reload();
        })
        .catch(function (err) { alert(err.message || l('An error occurred')); });
    });

    document.getElementById('deleteInt').addEventListener('click', function () {
        var id = document.getElementById('deleteMenuId').value;
        fetch('/api/menu/' + id, {
            method: 'DELETE',
            headers: { 'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content }
        })
        .then(function (r) {
            if (!r.ok) {
                return r.json().then(function (body) {
                    var msg = (body && body.errors ? body.errors.map(function (e) { return e.message; }).join('; ') : null)
                        || (body ? body.message : null) || r.statusText;
                    throw new Error(msg);
                });
            }
            return r.json();
        })
        .then(function () {
            bootstrap.Modal.getInstance(document.getElementById('confirmDeleteMenu')).hide();
            window.location.reload();
        })
        .catch(function (err) { alert(err.message || l('An error occurred')); });
    });

})();
