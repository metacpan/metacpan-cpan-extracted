formTools = {
    dragstart: function (ev) {
        ev.dataTransfer.setData("text/plain", ev.target.id);
        // Tell the browser both copy and move are possible
        ev.effectAllowed = "copy";

        jQuery(ev.target).addClass('current');
        jQuery(ev.target).find('.formtools-element-placeholder').addClass('hidden');
        jQuery(ev.target).next().find('.formtools-element-placeholder').addClass('hidden');
    },

    dragenter: function (ev) {
        ev.preventDefault();
        jQuery(ev.target).closest('.formtools-content').find('.formtools-element-placeholder').removeClass('active');
        jQuery(ev.target).closest('.formtools-element').children('.formtools-element-placeholder').addClass('active');
    },

    dragleave: function (ev) {
        ev.preventDefault();
    },

    dragover: function (ev) {
        ev.preventDefault();
        if ( ev.target.classList.contains('formtools-content') ) {
            const last_element = jQuery(ev.target).find('.formtools-element').get(-1);
            if ( last_element ) {
                const last_position = last_element.getBoundingClientRect();
                if ( ev.y > last_position.y + last_position.height ) {
                    jQuery(ev.target).find('.formtools-element .formtools-element-placeholder').removeClass('active');
                    jQuery(ev.target).children('.formtools-element-placeholder').addClass('active');
                }
            }
        }
    },

    drop: function (ev) {
        ev.preventDefault();

        const source = document.getElementById(ev.dataTransfer.getData("text"));

        const sibling = ev.target.closest('.formtools-element');
        const area = ev.target.closest('.formtools-content');
        if ( source.closest('.formtools-content') ) {
            if ( sibling ) {
                area.insertBefore(source, sibling);
            }
            else {
                area.insertBefore(source, area.children[area.children.length-1]);
            }
        }
        else {
            const source_copy = source.cloneNode(true);

            const old_id = source_copy.id;
            source_copy.id = 'formtools-element-' + area.dataset.pageId + '-' + Date.now();
            jQuery(source_copy).attr('ondragenter', 'formTools.dragenter(event);');
            jQuery(source_copy).find('a.edit').attr('data-target', '#' + source_copy.id + '-modal' );
            if ( sibling ) {
                area.insertBefore(source_copy, sibling);
            }
            else {
                area.insertBefore(source_copy, area.children[area.children.length-2]);
            }

            const modal_copy = jQuery('#' + old_id + '-modal').clone(true);
            jQuery('div.modal-wrapper:visible').append(modal_copy);
            modal_copy.attr('id', source_copy.id + '-modal' );
            modal_copy.find('form.formtools-element-form').on('submit', formTools.elementSubmit);
            modal_copy.modal('show');
            modal_copy.attr('ondragenter', 'formTools.dragenter(event);');

            modal_copy.find(':input[name^="template-"]').each(function() {
                const input = jQuery(this);
                input.attr('name', input.attr('name').replace(/^template-/, ''));
            });
            modal_copy.find('select:not(.combobox)').selectpicker();

            modal_copy.find('.custom-checkbox, .custom-radio').each(function() {
                const input = jQuery(this).find('input');
                const label = jQuery(this).find('label');
                label.attr('for', source_copy.id + label.attr('for').replace(/^template-/, ''));
                input.attr('id', source_copy.id + input.attr('id').replace(/^template-/, ''));
            });

            // combobox dropdown icon doesn't work after drag&drop, hide it for now
            modal_copy.find('.combobox-container .input-group-append').hide();
        }
        formTools.submit();
    },

    dragend: function (ev) {
        jQuery('.formtools-content:visible').find('.formtools-element-placeholder').removeClass('active hidden');
        jQuery('.formtools-content:visible').find('.formtools-element').removeClass('current');
        jQuery('.formtools-component-menu').find('.formtools-element').removeClass('current');
    },

    elementSubmit: function(e) {
        e.preventDefault();
        const form = jQuery(this);
        const modal = form.closest('.formtools-element-modal');
        const element = jQuery('#' + modal.attr('id').replace(/-modal$/, ''));
        const value = element.data('value');

        if ( value.type === 'raw_html' ) {
            const input = form.find(':input[name=content]');
            const content = input.val();
            const wrapper = input.data('wrapper');
            if ( wrapper ) {
                value.content = content;
                value.wrapper = wrapper;

                const alignment = form.find(':input[name=alignment]').val();
                value.alignment = alignment;
                value.html = '<' + wrapper + ( alignment ? ' class="text-' + alignment.toLowerCase() + '"' : '' ) + '>' + content + '</' + wrapper + '>';
            }
            else {
                value.html = content;
            }
            element.find('span.content').text(content.length > 40 ? content.substr(0, 40) + '...' : content);
        }
        else if ( value.type === 'component' && value.comp_name === 'Field' ) {
            const label = form.find(':input[name=label]').val();
            if ( label && label.length ) {
                value.arguments.label = label;
                element.find('span.label').text('(' + label + ')');
            }
            else {
                element.find('span.label').text('');
                delete value.arguments.label;
            }

            let default_value;
            form.find(':input[name^="Object-"][name*="-CustomField-"]:not([name$="-Magic"])').each(function() {
                const input = jQuery(this);
                if ( input.is('[type=radio], [type=checkbox]') ) {
                    if ( input.is(':checked') ) {
                        if ( default_value ) {
                            if ( !Array.isArray(default_value) ) {
                                default_value = [default_value];
                            }
                            default_value.push(input.val());
                        }
                        else {
                            default_value = input.val();
                        }
                    }
                }
                else {
                    default_value = input.val();
                }
            });

            if ( !default_value ) {
                const default_input = form.find(':input[name=default]');
                if ( default_input ) {
                    default_value = default_input.val();
                }
            }

            if ( default_value && default_value.length ) {
                value.arguments.default = default_value;
            }
            else {
                delete value.arguments.default;
            }

            const tooltip = form.find(':input[name=tooltip]').val();

            if ( tooltip && tooltip.length ) {
                value.arguments.tooltip = tooltip;
            }
            else {
                delete value.arguments.tooltip;
            }

            const validation = form.find(':input[name=validation]');
            if ( validation.length ) {
                if ( validation.is(':checked') ) {
                    value.arguments.validation = 1;
                }
                else {
                    delete value.arguments.validation;
                }
            }

            const dependent_validation = form.find(':input[name=dependent_validation]');
            if ( dependent_validation.length ) {
                value.arguments.dependent_validation ||= {};
                if ( dependent_validation.is(':checked') ) {
                    value.arguments.dependent_validation.enabled = 1;
                }
                else {
                    value.arguments.dependent_validation.enabled = 0;
                }
            }

            const dependent_name = form.find(':input[name=dependent_name]');
            if ( dependent_name.length ) {
                value.arguments.dependent_validation ||= {};
                value.arguments.dependent_validation.name = dependent_name.val();
            }

            const dependent_value = form.find(':input[name=dependent_value]');
            if ( dependent_value.length ) {
                value.arguments.dependent_validation ||= {};
                value.arguments.dependent_validation.values = dependent_value.val();
            }

            const hide = form.find(':input[name=hide]');
            if ( hide.length ) {
                if ( hide.is(':checked') ) {
                    value.arguments.render_as = 'hidden';
                }
                else if ( value.arguments.render_as === 'hidden' ) {
                    delete value.arguments.render_as;
                }
            }

            const readonly = form.find(':input[name=readonly]');
            if ( readonly.length ) {
                if ( readonly.is(':checked') ) {
                    value.arguments.render_as = 'readonly_plus_values';
                }
                else if ( value.arguments.render_as === 'readonly_plus_values' ) {
                    delete value.arguments.render_as;
                }
            }

            const include = form.find(':input[name=include_in_content]');
            if ( include.length ) {
                if ( include.is(':checked') ) {
                    value.arguments.include_in_content = '1';
                }
                else if ( value.arguments.include_in_content === '1' ) {
                    delete value.arguments.include_in_content;
                }
            }
        }
        else if ( value.type === 'hidden' ) {
            value['input-name'] = form.find(':input[name=name]').val();
            value['input-value'] = form.find(':input[name=value]').val();
            element.find('span.content').text(value['input-name'] + ': ' + value['input-value']);
        }

        const show_condition = form.find(':input[name=show_condition]');
        if ( show_condition.length ) {
            value.arguments ||= {};
            value.arguments.show_condition ||= {};
            if ( show_condition.is(':checked') ) {
                value.arguments.show_condition.enabled = 1;
            }
            else {
                value.arguments.show_condition.enabled = 0;
            }
        }

        const show_condition_name = form.find(':input[name=show_condition_name]');
        if ( show_condition_name.length ) {
            value.arguments.show_condition ||= {};
            value.arguments.show_condition.name = show_condition_name.val();
        }

        const show_condition_value = form.find(':input[name=show_condition_value]');
        if ( show_condition_value.length ) {
            value.arguments.show_condition ||= {};
            value.arguments.show_condition.values = show_condition_value.val();
        }

        element.data('value', value);
        form.closest('.formtools-element-modal').modal('hide');
        formTools.submit();
    },

    pageSubmit: function(e) {
        e.preventDefault();
        const form = jQuery(this);
        jQuery('#formtools-pages a.nav-link.active').text(form.find('input[name=name]').val());
        form.closest('.formtools-page-modal').modal('hide');
        formTools.submit();
    },

    submit: function(e) {
        const form = jQuery(e ? e.target : '#formtools-form-modify');
        const content = {};
        jQuery('div.formtools-content').each(function() {
            let page = jQuery(this).data('page');
            content[page] ||= {};

            for ( let attr of ['name', 'sort_order'] ) {
                content[page][attr] = jQuery(this).closest('div.tab-pane').find(':input[name="' + attr + '"]').val();
            }

            content[page]['content'] ||= [];
            jQuery(this).children('.formtools-element').each(function() {
                content[page]['content'].push(jQuery(this).data('value'));
            });
        });
        form.find('input[name=ActiveTab]').val(jQuery('.formtools-content:visible').data('page-id'));

        const serialized_content = JSON.stringify(content);
        if ( !form.data('old-value') ) {
            form.data('old-value', serialized_content);
        }
        else if ( serialized_content === form.data('old-value') ) {
            jQuery('.formtools-form-pages .pending-changes').addClass('hidden');
        }
        else {
            jQuery('.formtools-form-pages .pending-changes').removeClass('hidden');
        }
        form.find('input[name=Content]').val(JSON.stringify(content));

        if (e) { // It's a real form submitting
            form.addClass('submitting');
        }
        else {
            form.removeClass('submitting');
        }
    },

    deleteElement: function(event) {
        jQuery(event.target).find('[data-toggle=tooltip]').tooltip('hide');
        const element = event.target.closest('.formtools-element');
        const modal = document.getElementById(element.id + '-modal');
        if ( modal ) {
            modal.remove();
        }
        element.remove();
        formTools.submit();
        return false;
    },

    deletePage: function() {
        jQuery('.formtools-page-modal.show').modal('hide');
        const tab = jQuery(this).closest('.tab-pane');
        jQuery('#formtools-pages').find('li:first a.nav-link').tab('show');
        jQuery('#formtools-pages').find('a.nav-link[href="#' + tab.attr('id') + '"]').closest('li').remove();
        setTimeout( function() {
            tab.remove();
            formTools.submit();
        }, 500 );
        return false;
    },

    refreshSource: function () {
        var searchTerm = jQuery(this).val().toLowerCase();
        if ( searchTerm.length ) {
            // Hide the separator on search, considering some sections might not have any matched items.
            jQuery('.formtools-component-menu').find('hr').hide();
            jQuery('.formtools-component-menu').find('.formtools-element').each(function () {
                var item = jQuery(this);
                if (item.find('span.content').text().toLowerCase().indexOf(searchTerm) > -1) {
                    item.show();
                }
                else {
                    item.hide();
                }
            });
        }
        else {
            jQuery('.formtools-component-menu').find('hr').show();
            jQuery('.formtools-component-menu').find('.formtools-element').show();
        }
    }
};
