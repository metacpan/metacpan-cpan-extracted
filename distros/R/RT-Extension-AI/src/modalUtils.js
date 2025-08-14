import { extractParagraphsFromHTML, getTicketIdFromUrl } from './aiUtils.js';

export class ModalManager {
    constructor() {
        this.modalInstance = null;
        this.modalElement = null;

        this.close = this.close.bind(this);
    }

    /**
     * Ensures Bootstrap is available before proceeding
     * @returns {boolean} Whether Bootstrap is available
     */
    checkBootstrapAvailability() {
        if (typeof bootstrap === 'undefined') {
            console.error('Bootstrap is not available. Make sure it is properly loaded.');
            return false;
        }
        return true;
    }

    /**
     * Opens a modal with the provided HTML content.
     * @param {string} content - The HTML content to display inside the modal.
     * @returns {boolean} Whether the modal was successfully opened
     */
    open(content) {
        // Check Bootstrap availability first
        if (!this.checkBootstrapAvailability()) {
            return false;
        }

        try {
            this.closeExistingModal();

            const tempDiv = document.createElement('div');
            tempDiv.innerHTML = content.trim();

            const modalElement = tempDiv.querySelector('#aiModal');

            if (!modalElement) {
                console.error('Modal element #aiModal not found in the provided content');
                return false;
            }

            tempDiv.removeChild(modalElement);
            document.body.appendChild(modalElement);

            this.modalElement = modalElement;

            this.modalInstance = new bootstrap.Modal(modalElement, {
                backdrop: true,
                keyboard: true
            });

            this.modalInstance.show();

            this.setupCloseHandlers(modalElement);

            return true;
        } catch (error) {
            console.error('Error opening modal:', error);
            return false;
        }
    }

    /**
     * Set up event handlers for closing the modal
     * @param {HTMLElement} modalElement - The modal DOM element
     */
    setupCloseHandlers(modalElement) {
        const closeButtons = modalElement.querySelectorAll(
            '.close, .btn-close, [data-bs-dismiss="modal"]'
        );
        closeButtons.forEach((button) => {
            button.removeEventListener('click', this.close.bind(this));
            button.addEventListener('click', this.close.bind(this));
        });
    }

    /**
     * Close any existing modal instance
     */
    closeExistingModal() {
        try {
            if (this.modalInstance) {
                this.modalInstance.hide();
                this.modalInstance.dispose();
                this.modalInstance = null;
            }

            if (this.modalElement && this.modalElement.parentNode) {
                this.modalElement.parentNode.removeChild(this.modalElement);
            }

            const backdrops = document.querySelectorAll('.modal-backdrop');
            backdrops.forEach((backdrop) => {
                if (backdrop && backdrop.parentNode) {
                    backdrop.parentNode.removeChild(backdrop);
                }
            });

            document.body.classList.remove('modal-open');
            document.body.style.removeProperty('padding-right');
            document.body.style.removeProperty('overflow');

            this.modalElement = null;
        } catch (e) {
            console.warn('Error disposing existing modal:', e);
        }
    }

    /**
     * Closes the modal
     */
    close() {
        try {
            if (this.modalInstance) {
                this.modalInstance.hide();
                this.modalInstance.dispose();
                this.modalInstance = null;
            }

            if (this.modalElement && this.modalElement.parentNode) {
                this.modalElement.parentNode.removeChild(this.modalElement);
            }

            this.modalElement = null;
        } catch (e) {
            console.warn('Error closing modal:', e);
            if (this.modalElement && this.modalElement.parentNode) {
                this.modalElement.parentNode.removeChild(this.modalElement);
            }

            const backdrops = document.querySelectorAll('.modal-backdrop');
            backdrops.forEach((backdrop) => {
                backdrop.parentNode.removeChild(backdrop);
            });

            document.body.classList.remove('modal-open');
            document.body.style.removeProperty('padding-right');
            document.body.style.removeProperty('overflow');
        }
    }
}

/**
 * Load modal content dynamically via HTMX (or AJAX fallback).
 * @param {string} url - The endpoint to fetch modal content from.
 * @param {Object} params - Optional parameters to pass with the request.
 * @returns {Promise<string>} The HTML content for the modal.
 */
export async function loadModalContent(url, params = {}) {
    const query = new URLSearchParams(params).toString();
    const fetchUrl = `${url}?${query}`;

    try {
        const response = await fetch(fetchUrl, {
            method: 'GET',
            headers: {
                'X-Requested-With': 'XMLHttpRequest'
            }
        });

        if (!response.ok) {
            throw new Error(`Failed to fetch modal content: ${response.status} ${response.statusText}`);
        }

        return await response.text();
    } catch (error) {
        console.error('Error loading modal content:', error);
        throw error;
    }
}

/**
 * Save the current selection in the editor.
 * @param {Object} editor - The CKEditor instance
 * @returns {Object} The saved selection state
 */
function saveEditorSelection(editor) {
    if (!editor || !editor.model || !editor.model.document) {
        console.warn('Editor not properly initialized when trying to save selection');
        return { ranges: [], attributes: [] };
    }

    const selection = editor.model.document.selection;
    const ranges = Array.from(selection.getRanges()).map((range) => range.clone());
    const attributes = Array.from(selection.getAttributes());
    return { ranges, attributes };
}

/**
 * Restore a saved selection in the editor.
 * @param {Object} editor - The CKEditor instance
 * @param {Object} savedSelection - The previously saved selection state
 */
function restoreEditorSelection(editor, savedSelection) {
    if (!editor || !editor.model) {
        console.warn('Editor not properly initialized when trying to restore selection');
        return;
    }

    if (!savedSelection || !savedSelection.ranges) {
        console.warn('Invalid saved selection when trying to restore');
        return;
    }

    editor.model.change((writer) => {
        try {
            writer.setSelection(savedSelection.ranges);

            for (const [key, value] of savedSelection.attributes) {
                writer.setSelectionAttribute(key, value);
            }
        } catch (e) {
            console.error('Error restoring editor selection:', e);
        }
    });
}

/**
 * Creates a modal for AI suggestions to be used with the editor
 * @param {string} editorContent - The current content of the editor
 * @param {Object} editor - The CKEditor instance
 * @param {string} callType - The type of AI call to make
 * @param {boolean} isSelectedText - Whether the text is selected
 * @returns {Promise<void>}
 */
export async function createSuggestionModal(
    editorContent,
    editor,
    callType = 'suggest_response',
    isSelectedText = false
) {
    if (!editor || !editor.model) {
        console.error('Editor not properly initialized');
        return;
    }

    try {
        if (typeof bootstrap === 'undefined') {
            console.error('Bootstrap is required but not available');
            return;
        }

        editorContent = extractParagraphsFromHTML(editorContent);

        const savedSelection = saveEditorSelection(editor);
        let modalHtml;
        // Can be null on create ticket page
        const ticketId = getTicketIdFromUrl(window.location.href);
        let queueId;
        if ( !ticketId ) {
            queueId = document.querySelector('#ai-queue')?.getAttribute('data-id');
        }

        try {
            modalHtml = await loadModalContent(RT.Config.WebHomePath + '/Helpers/AISuggestion/ShowModal', {
                rawText: editorContent,
                callType,
                ...(ticketId && { TicketId: ticketId }),
                ...(queueId && { QueueId: queueId })
            });
        } catch (error) {
            console.error('Failed to load modal content:', error);
            alert('Failed to load AI suggestion modal. Please try again later.');
            return;
        }

        const modalManager = new ModalManager();
        const modalOpened = modalManager.open(modalHtml);

        if (!modalOpened) {
            console.error('Failed to open modal');
            return;
        }

        setTimeout(() => {
            try {
                const doneButton = modalManager.modalElement.querySelector('[name="done-button"]');
                const suggestionText = modalManager.modalElement.querySelector('[name="ai-result"]');

                if (!suggestionText) {
                    console.error('suggestionText element not found in modal content');
                    return;
                }

                if (typeof htmx !== 'undefined') {
                    htmx.process(modalManager.modalElement);
                }

                if (doneButton) {
                    doneButton.replaceWith(doneButton.cloneNode(true));
                    const newDoneButton = modalManager.modalElement.querySelector('[name="done-button"]');

                    newDoneButton.addEventListener('click', () => {
                        const aiResponse = suggestionText?.innerText?.replace(/^\s*|\s*$/g, '').trim();

                        if (!aiResponse) {
                            console.warn('No AI response to insert');
                            modalManager.close();
                            return;
                        }

                        try {
                            editor.model.change((writer) => {
                                try {
                                    const modelFragment = editor.data.toModel(
                                        editor.data.processor.toView(aiResponse)
                                    );

                                    if (!savedSelection.ranges.length || !isSelectedText) {
                                        const root = editor.model.document.getRoot();
                                        writer.setSelection(null);
                                        writer.remove(writer.createRangeIn(root));
                                        writer.insert(modelFragment, writer.createPositionAt(root, 0));
                                    } else {
                                        restoreEditorSelection(editor, savedSelection);
                                        editor.model.insertContent(modelFragment, editor.model.document.selection);
                                    }

                                    const root = editor.model.document.getRoot();
                                    const position = writer.createPositionAt(root, 'end');
                                    writer.setSelection(position);

                                    setTimeout(() => {
                                        editor.editing.view.focus();
                                    }, 100);
                                } catch (e) {
                                    console.error('Error inserting content into editor:', e);
                                    alert('Failed to insert AI suggestion into the editor.');
                                }
                            });
                        } catch (e) {
                            console.error('Error applying editor changes:', e);
                        }

                        modalManager.close();
                    });
                } else {
                    console.warn('Done button not found in modal content');
                }
            } catch (err) {
                console.error('Error setting up modal interaction:', err);
            }
        }, 100);
    } catch (error) {
        console.error('Error creating suggestion modal:', error);
        alert('An error occurred while creating the AI suggestion modal.');
    }
}
