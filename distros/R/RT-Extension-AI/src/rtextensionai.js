import { fetchAiResults, getEditorSelectionOrContent, stripHTML, isAIEditorPage } from './aiUtils.js';
import { showAutocompletePlaceholder } from './suggestion.js';

const aiIcon = `
<svg width="68" height="64" viewBox="0 0 68 64" xmlns="http://www.w3.org/2000/svg">
  <g fill="none" fill-rule="evenodd">
    <path d="M34 2C17.432 2 4 15.432 4 32s13.432 30 30 30 30-13.432 30-30S50.568 2 34 2zm0 56C19.561 58 8 46.439 8 32S19.561 6 34 6s26 11.561 26 26-11.561 26-26 26z" fill="#1E90FF" fill-rule="nonzero"/>
    <path d="M47.5 23.5c0 7.732-6.268 14-14 14s-14-6.268-14-14 6.268-14 14-14 14 6.268 14 14zm-3 0c0-6.075-4.925-11-11-11s-11 4.925-11 11 4.925 11 11 11 11-4.925 11-11z" fill="#1EBC61" fill-rule="nonzero"/>
    <path d="M34 14.5c-1.104 0-2 .896-2 2v13c0 1.104.896 2 2 2s2-.896 2-2v-13c0-1.104-.896-2-2-2z" fill="#FFD700"/>
    <path d="M34 37c-1.104 0-2 .896-2 2v3c0 1.104.896 2 2 2s2-.896 2-2v-3c0-1.104-.896-2-2-2z" fill="#FFD700"/>
    <path d="M22.5 23.5c-.552 0-1 .448-1 1v6c0 .552.448 1 1 1h7c.552 0 1-.448 1-1v-6c0-.552-.448-1-1-1h-7zm21 0c-.552 0-1 .448-1 1v6c0 .552.448 1 1 1h7c.552 0 1-.448 1-1v-6c0-.552-.448-1-1-1h-7z" fill="#FFF" fill-rule="nonzero"/>
    <circle cx="34" cy="32" r="2.5" fill="#FFF"/>
  </g>
</svg>`;

import { createSuggestionModal } from './modalUtils.js';

export default class RtExtensionAi extends CKEDITOR.Plugin {
    static get pluginName() {
        return 'RtExtensionAi';
    }

    init() {
        const editor = this.editor;

        if ( isAIEditorPage() ) {
            this.addDropdown(editor);
            this.addAutoComplete(editor);
        }
    }

    /**
     * Adds a dropdown with AI suggestions, Adjust Tone, and Translate options.
     */
    addDropdown(editor) {
        editor.ui.componentFactory.add('aiSuggestion', (locale) => {
            const dropdownItems = new CKEDITOR.Collection();

            dropdownItems.add(this.createDropdownItem('Adjust Tone/Voice', 'adjust_tone'));
            dropdownItems.add(this.createDropdownItem('AI Suggestion', 'suggest_response'));
            dropdownItems.add(this.createDropdownItem('Translate', 'translate_content'));

            const dropdownView = CKEDITOR.createDropdown(locale, CKEDITOR.DropdownButtonView);

            CKEDITOR.addListToDropdown(dropdownView, dropdownItems);

            dropdownView.buttonView.set({
                label: 'AI Assist',
                tooltip: true,
                withText: true
            });

            dropdownView.on('execute', async (evt) => {
                const { id } = evt.source;
                const { content, isSelected: isSelectedText } = getEditorSelectionOrContent(editor);

                createSuggestionModal(content, editor, id, isSelectedText);
            });

            return dropdownView;
        });
    }

    /**
     * Adds real-time auto-complete functionality triggered by typing.
     */
    addAutoComplete(editor) {
        let debounceTimeout = null;
        let isAppending = false;

        editor.model.document.on('change:data', () => {
            clearTimeout(debounceTimeout);
            debounceTimeout = setTimeout(async () => {
                if (isAppending) {
                    isAppending = false;
                    return;
                }

                const text = stripHTML(editor.data.get().trim());

                if (!text) {
                    return;
                }

                try {
                    const suggestion = await fetchAiResults(text, 'autocomplete_text');

                    if (suggestion) {
                        showAutocompletePlaceholder(editor, suggestion);
                        isAppending = true;
                    }
                } catch (error) {
                    console.error('Error during auto-complete:', error);
                }
            }, 500);
        });
    }

    /**
     * Creates an individual dropdown item.
     */
    createDropdownItem(label, id) {
        return {
            type: 'button',
            model: {
                label,
                id,
                withText: true
            }
        };
    }
}
