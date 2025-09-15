import { Head, Link, Form } from '@inertiajs/react'
import ErrorDisplay from '../../components/ErrorDisplay'

interface Todo {
  id: number
  title: string
  completed: boolean
}

interface Props {
  todos: Todo[]
  errors: Record<string, string>
  values?: {
    title?: string
  }
}

export default function TodosIndex({ todos, errors, values }: Props) {

  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4">
      <Head title="Todos" />
      <div className="max-w-2xl mx-auto">
        <h1 className="text-3xl font-bold text-gray-900 mb-8">Todo List</h1>

        <ErrorDisplay errors={errors} />

        <Form method="post" action="/todos" className="mb-8 bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <div className="flex gap-2">
            <input
              type="text"
              name="title"
              defaultValue={values?.title || ''}
              placeholder="Enter a new todo..."
              className={`flex-1 px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                errors.title ? 'border-red-500' : 'border-gray-300'
              }`}
            />
            <button
              type="submit"
              className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
            >
              Add Todo
            </button>
          </div>
          {errors.title && (
            <p className="mt-1 text-sm text-red-600">{errors.title}</p>
          )}
        </Form>

        <div className="space-y-2">
          {todos.length === 0 ? (
            <p className="text-gray-500 text-center py-8">No todos yet. Add one above!</p>
          ) : (
            todos.map(todo => (
              <Link
                key={todo.id}
                href={`/todos/${todo.id}`}
                className={`block p-4 bg-white rounded-lg border border-gray-200 hover:border-blue-500 transition-colors ${
                  todo.completed ? 'opacity-60' : ''
                }`}
              >
                <div className="flex items-center justify-between">
                  <span className={todo.completed ? 'line-through' : ''}>
                    {todo.title}
                  </span>
                  <span className="text-2xl">
                    {todo.completed ? '✓' : '○'}
                  </span>
                </div>
              </Link>
            ))
          )}
        </div>

        <div className="mt-8">
          <Link
            href="/"
            className="text-blue-600 hover:underline"
          >
            ← Back to Home
          </Link>
        </div>
      </div>
    </div>
  )
}
