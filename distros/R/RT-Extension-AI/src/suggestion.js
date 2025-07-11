/**
 * Render the auto-complete placeholder on the editor.
 * @param {Object} editor - CKEditor instance.
 * @param {string} suggestion - Suggestion from AI.
 */
export function showAutocompletePlaceholder(editor, suggestion) {
    if (!suggestion || !editor) {
        console.error('Invalid suggestion or editor instance.');
        return;
    }

    editor.model.change((writer) => {
        const root = editor.model.document.getRoot();

        if (editor.model.markers.has('autocompleteSuggestion')) {
            writer.removeMarker('autocompleteSuggestion');
        }

        const position =
            editor.model.document.selection.getFirstPosition() || writer.createPositionAt(root, 'end');

        const range = writer.createRange(position, position);
        writer.addMarker('autocompleteSuggestion', {
            range,
            usingOperation: false,
            affectsData: false
        });

        insertPlaceholderWithTab(editor, suggestion);
    });
}

/**
 * Handle user action of pressing Tab to accept the auto-complete suggestion.
 * @param {Object} editor - CKEditor instance.
 * @param {string} suggestion - Suggestion from AI.
 */
export function insertPlaceholderWithTab(editor, suggestion) {
    if (!suggestion || !editor) {
        console.error('Invalid suggestion or editor instance.');
        return;
    }

    const styleId = 'placeholder-autocomplete-style';
    if (!document.getElementById(styleId)) {
        const style = document.createElement('style');
        style.id = styleId;
        style.innerHTML = `
            .placeholder-autocomplete-text {
                color: gray;
                opacity: 0.5;
            }
        `;
        document.head.appendChild(style);
    }

    let placeholderElement = null;

    editor.editing.view.change((viewWriter) => {
        const selection = editor.model.document.selection;

        const placeholderText = viewWriter.createText(suggestion);
        placeholderElement = viewWriter.createContainerElement('span', {
            class: 'placeholder-autocomplete-text'
        });

        const viewPosition = editor.editing.mapper.toViewPosition(selection.getFirstPosition());
        if (viewPosition) {
            viewWriter.insert(viewPosition, placeholderElement);
            viewWriter.insert(viewWriter.createPositionAt(placeholderElement, 0), placeholderText);
        }
    });

    editor.keystrokes.set('Tab', (event, cancel) => {
        if (placeholderElement) {
            editor.model.change((writer) => {
                const position = editor.model.document.selection.getFirstPosition();
                if (position) {
                    writer.insertText(suggestion, position);

                    const newPosition = writer.createPositionAt(
                        position.parent,
                        position.offset + suggestion.length
                    );
                    writer.setSelection(newPosition);

                    editor.editing.view.change((viewWriter) => {
                        viewWriter.remove(placeholderElement);
                    });
                    placeholderElement = null;
                }
            });

            cancel();
        }
    });

    editor.ui.view.editable.element.addEventListener('click', () => {
        if (placeholderElement) {
            editor.editing.view.change((viewWriter) => {
                viewWriter.remove(placeholderElement);
            });
            placeholderElement = null;
        }
    });

    document.addEventListener('click', (event) => {
        const editorElement = editor.ui.view.editable.element;
        if (!editorElement.contains(event.target) && placeholderElement) {
            editor.editing.view.change((viewWriter) => {
                viewWriter.remove(placeholderElement);
            });
            placeholderElement = null;
        }
    });

    editor.model.document.on('change:data', () => {
        if (placeholderElement) {
            editor.editing.view.change((viewWriter) => {
                viewWriter.remove(placeholderElement);
            });
            placeholderElement = null;
        }
    });
}
